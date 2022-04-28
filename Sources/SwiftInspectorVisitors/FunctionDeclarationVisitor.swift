import SwiftSyntax

public final class FunctionDeclarationVisitor: SyntaxVisitor {
  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.identifier.withoutTrivia().description
    let functionSignatureVisitor = FunctionSignatureVisitor()
    functionSignatureVisitor.walk(node)
    let info = FunctionDeclarationInfo(
      name: name,
      arguments: functionSignatureVisitor.arguments,
      returnType: functionSignatureVisitor.returnType)
    functionDeclarations.append(info)
    return .skipChildren
  }

  public var functionDeclarations: [FunctionDeclarationInfo] = []
}

fileprivate final class FunctionSignatureVisitor: SyntaxVisitor {
  override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    guard
      let argumentLabelName = node.firstName?.text,
      let type = node.type?.typeDescription
    else { return .skipChildren }

    appendArgument(argumentLabelName: argumentLabelName, type: type)
    return .skipChildren
  }
  override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
    returnType = node.returnType.typeDescription
    return .skipChildren
  }

  fileprivate func appendArgument(argumentLabelName: String, type: TypeDescription) {
    var arguments = self.arguments ?? []
    arguments.append(.init(argumentLabelName: argumentLabelName, type: type))
    self.arguments = arguments
  }

  fileprivate var arguments: [FunctionDeclarationInfo.ArgumentInfo]?
  fileprivate var returnType: TypeDescription?
}

public struct FunctionDeclarationInfo: Codable, Hashable {
  public let name: String
  public let arguments: [ArgumentInfo]?
  public let returnType: TypeDescription?

  /// A convenience for creating a selector string that can be reference in Objective-C code.
  public var selectorName: String {
    "\(name)(\((arguments ?? []).map { "\($0.argumentLabelName):" }.joined()))"
  }

  public struct ArgumentInfo: Codable, Hashable {
    public let argumentLabelName: String
    public let type: TypeDescription
  }
}
