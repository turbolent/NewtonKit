import HTML
import NSOF
import Foundation


fileprivate extension NewtonSymbol {
    static let para = NewtonSymbol(name: "para")
}

public struct Document: Equatable {
    var creationDate: Date?
    var lastModifiedDate: Date?
    var html: String
}


public func translateToDocument(paperroll: NewtonFrame) -> Document {

    let creationDate = paperroll.getInteger("timestamp")
        .map { Date(minutesSince1904: Int($0)) }

    let lastModifiedDate = paperroll.getInteger("_modTime")
        .map { Date(minutesSince1904: Int($0)) }

    let htmlDocument = translateToHTMLDocument(paperroll: paperroll)
    var html = ""
    render(node: htmlDocument, into: &html)

    return Document(
        creationDate: creationDate,
        lastModifiedDate: lastModifiedDate,
        html: html
    )
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

public func translateToHTMLDocument(paperroll: NewtonFrame) -> Node {
    let dataValues = (paperroll["data"] as? NewtonPlainArray)?.values ?? []

    let nodesAndDimensions =
        dataValues
            .compactMap(translateToHTMLNode)
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

    return .Element(
        tag: "html",
        child: .Fragment([
            .Element(
                tag: "head",
                child: .Fragment([
                    .Element(tag: "title", child: .Text("")),
                    .Element(tag: "style", child: .Text(noteStyle))
                ])
            ),
            .Element(
                tag: "body",
                attributes: [
                    (key: "style", value: "height: \(height)px"),
                    (key: "id", value: "content")
                ],
                child: .Fragment(nodesAndDimensions.map { $0.0 })
            )
        ])
    )
}


public func translateToHTMLNode(paperrollDataObject: NewtonObject) -> (Node, Dimensions)? {

    guard
        let frame = paperrollDataObject as? NewtonFrame,
        let viewStationery = frame["viewStationery"] as? NewtonSymbol
    else {
        return nil
    }

    switch viewStationery {
    case .para:
        return translateToHTMLNode(paraFrame: frame)
    default:
        return nil
    }
}


public func translateToHTMLNode(paraFrame: NewtonFrame) -> (Node, Dimensions)? {

    guard
        let text = paraFrame.getString("text"),
        let dimensions = paraFrame["viewBounds"]
            .flatMap({ convertDimensions(dimensionsObject: $0) })
    else {
        return nil
    }

    let left = dimensions.left
    let width = dimensions.right - left
    let top = dimensions.top
    let height = dimensions.bottom - top

    let styleAttribute = [
        "position: absolute",
        "left: \(left)px",
        "width: \(width)px",
        "top: \(top)px",
        "height: \(height)px"
    ].joined(separator: "; ")

    let encoded = escapeText(text)
        .replacingOccurrences(of: "\r", with: "<br>")
        .replacingOccurrences(of: " ", with: "&nbsp;")

    return (
        .Element(
            tag: "p",
            attributes: [
                (key: "style", value: styleAttribute)
            ],
            child: .Raw(encoded)
        ),
        dimensions
    )
}

public func convertDimensions(dimensionsObject: NewtonObject) -> Dimensions? {

    if let frame = dimensionsObject as? NewtonFrame,
        let top = frame.getInteger("top"),
        let left = frame.getInteger("left"),
        let bottom = frame.getInteger("bottom"),
        let right = frame.getInteger("right") {

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
