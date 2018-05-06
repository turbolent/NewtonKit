import Html
import NSOF


public struct Dimensions {
    let top: Int32
    let left: Int32
    let bottom: Int32
    let right: Int32
}


fileprivate extension NewtonSymbol {
    static let para = NewtonSymbol(name: "para")
}


private let noteStyle = """
  html {
    box-sizing: border-box;
    font-family: sans-serif;
    font-size: 18px;
    line-height: 24px;
    height: 100%;
  }
  *, *:before, *:after {
    box-sizing: inherit
  }
  * {
    margin: 0;
    padding: 0;
    font-weight: normal;
    font-style: normal;
    border: 0
  }
  body {
    height: 100%
  }
  #content {
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAA4CAAAAADlHub6AAAAFElEQVQY02P4DwUMo4xhz2BggDMASsm6VFaiatcAAAAASUVORK5CYII=');
    background-size: 4px 28px;
    margin-top: 2px;
    min-height: 100%;
  }
"""


public func translateToHtmlDocument(paperroll: NewtonFrame) -> Node {
    let dataValues = (paperroll["data"] as? NewtonPlainArray)?.values ?? []

    let nodesAndDimensions =
        dataValues
            .flatMap(translateToHtmlNode)
            .sorted { (left, right) -> Bool in
                let (_, d1) = left
                let (_, d2) = right
                if d1.top > d2.top {
                    return false
                }

                if d1.left > d2.left {
                    return false
                }

                return true
            }

    let height = nodesAndDimensions
        .map { $0.1.bottom }
        .max() ?? 0

    return document([
        html([
            head([
                style(noteStyle),
                title("")
            ]),
            body([
                div([
                        style("height: \(height)px"),
                        id("content")
                    ],
                    nodesAndDimensions.map { $0.0 })
            ])
        ])
    ])
}


public func translateToHtmlNode(paperrollDataObject: NewtonObject) -> (Node, Dimensions)? {

    guard
        let frame = paperrollDataObject as? NewtonFrame,
        let viewStationery = frame["viewStationery"] as? NewtonSymbol
    else {
        return nil
    }

    switch viewStationery {
    case .para:
        return translateToHtmlNode(paraFrame: frame)
    default:
        return nil
    }
}


// TODO:
// - escape text
// - spaces to &nbsp;
// - translate \r to <br>

public func translateToHtmlNode(paraFrame: NewtonFrame) -> (Node, Dimensions)? {

    guard
        let text = (paraFrame["text"] as? NewtonString)?.string,
        let dimensions = paraFrame["viewBounds"]
            .flatMap({ convertDimensions(dimensionsObject: $0) })
    else {
        return nil
    }

    let styleAttribute = [
        "position: absolute",
        "left: \(dimensions.left)px",
        "width: \(dimensions.right - dimensions.left)px",
        "top: \(dimensions.top)px",
        "height: \(dimensions.bottom - dimensions.top)px"
    ].joined(separator: "; ")

    return (
        p([
            style(styleAttribute)
        ], [
            Html.text(text)
        ]),
        dimensions
    )
}

public func convertDimensions(dimensionsObject: NewtonObject) -> Dimensions? {

    if let frame = dimensionsObject as? NewtonFrame,
        let top = (frame["top"] as? NewtonInteger)?.integer,
        let left = (frame["left"] as? NewtonInteger)?.integer,
        let bottom = (frame["bottom"] as? NewtonInteger)?.integer,
        let right = (frame["right"] as? NewtonInteger)?.integer {

        return Dimensions(top: top, left: left, bottom: bottom, right: right)
    }

    if let smallRect = dimensionsObject as? NewtonSmallRect {
        return Dimensions(top: Int32(smallRect.top),
                          left: Int32(smallRect.left),
                          bottom: Int32(smallRect.bottom),
                          right: Int32(smallRect.right))
    }

    return nil
}
