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


public func translateToHtmlDocument(paperroll: NewtonFrame) -> Node {
    let dataValues = (paperroll["data"] as? NewtonPlainArray)?.values ?? []

    return document([
        html([
            head([
                style("""
                    html {
                            box-sizing: border-box;
                            font-size: 18px;
                            line-height: 24px
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
                    """),
                title("")
            ]),
            body(dataValues.flatMap(translateToHtmlNode))
        ])
    ])
}


public func translateToHtmlNode(paperrollDataObject: NewtonObject) -> Node? {

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
// - escape test
// - spaces to &nbsp;
// - translate \r to <br>

public func translateToHtmlNode(paraFrame: NewtonFrame) -> Node? {

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
        ])
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
