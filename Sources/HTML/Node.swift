import Foundation

public enum Node {
    indirect case Element(
        tag: String,
        attributes: [(key: String, value: String?)] = [],
        child: Node = .Fragment([])
    )
    case Fragment([Node])
    case Text(String)
    case Raw(String)
}

// https://developer.mozilla.org/en-US/docs/Glossary/Void_element
public let voidElements: Set<String> = [
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
]

public func escapeText(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
}

public func escapeAttributeValue(_ value: String) -> String {
    value.replacingOccurrences(of: "\"", with: "&quot;")
}


public func render(node: Node, into output: inout String) {
    switch node {
    case let .Element(tag, attributes, child):
        output.append("<")
        output.append(tag)

        for (key, value) in attributes {
            output.append(" ")
            output.append(key)
            if let value {
                output.append("=\"")
                output.append(escapeAttributeValue(value))
                output.append("\"")
            }
        }
        output.append(">")

        render(node: child, into: &output)

        if !voidElements.contains(tag) {
            output.append("</")
            output.append(tag)
            output.append(">")
        }

    case let .Fragment(children):
        for child in children {
            render(node: child, into: &output)
        }

    case let .Text(string):
        output.append(escapeText(string))

    case let .Raw(string):
        output.append(string)
    }
}
