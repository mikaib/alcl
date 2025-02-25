package ast;

// ast node
@:structInit
class Node {
    public var type: NodeType;
    public var value: String;
    public var children: Array<Node> = [];
    public var parent: Node = null;
    public var line: Int = 0;
    public var column: Int = 0;
    public var endLine: Int = 0;
    public var endColumn: Int = 0;

    public function deepCopy(addParent: Bool = true): Node {
        var node: Node = {
            type: type,
            value: value,
            children: [],
            parent: addParent ? parent : null,
            line: line,
            column: column,
            endLine: endLine,
            endColumn: endColumn
        }
        for (child in children) {
            node.children.push(child.deepCopy(addParent));
        }
        return node;
    }

}
