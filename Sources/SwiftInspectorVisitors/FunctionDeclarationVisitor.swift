import SwiftSyntax

public final class FunctionDeclarationVisitor: SyntaxVisitor {
  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.identifier.withoutTrivia().description
    let functionSignatureVisitor = FunctionSignatureVisitor()
    functionSignatureVisitor.walk(node)
    let info = FunctionDeclarationInfo(name: name, returnType: functionSignatureVisitor.returnType)
    functionDeclarations.append(info)
    return .skipChildren
  }

  public var functionDeclarations: [FunctionDeclarationInfo] = []
}

fileprivate final class FunctionSignatureVisitor: SyntaxVisitor {
  override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
    returnType = node.returnType.typeDescription
    return .skipChildren
  }

  fileprivate var returnType: TypeDescription?
}

public struct FunctionDeclarationInfo: Codable, Hashable {
  public let name: String
  public let returnType: TypeDescription?
  // TODO: Add parameters and argument labels
}
