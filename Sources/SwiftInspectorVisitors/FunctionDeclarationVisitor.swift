import SwiftSyntax

public final class FunctionDeclarationVisitor: SyntaxVisitor {
  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.identifier.withoutTrivia().description

    let functionSignatureVisitor = FunctionSignatureVisitor()
    functionSignatureVisitor.walk(node)

    let modifiersVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      modifiersVisitor.walk(modifiers)
    }

    let info = FunctionDeclarationInfo(
      modifiers: modifiersVisitor.modifiers,
      name: name,
      parameters: functionSignatureVisitor.parameters,
      returnType: functionSignatureVisitor.returnType)
    functionDeclarations.append(info)
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a class declaration. This is a usage error: a single FunctionDeclarationVisitor instance should start walking only over a function declaration node")
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a struct declaration. This is a usage error: a single FunctionDeclarationVisitor instance should start walking only over a function declaration node")
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered an enum declaration. This is a usage error: a single FunctionDeclarationVisitor instance should start walking only over a function declaration node")
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a protocol declaration. This is a usage error: a single FunctionDeclarationVisitor instance should start walking only over a function declaration node")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered an extension declaration. This is a usage error: a single FunctionDeclarationVisitor instance should start walking only over a function declaration node")
    return .skipChildren
  }

  public var functionDeclarations: [FunctionDeclarationInfo] = []
}

fileprivate final class FunctionSignatureVisitor: SyntaxVisitor {
  override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    guard
      let firstMember = node.firstName?.text,
      let type = node.type?.typeDescription
    else { return .skipChildren }

    let secondMember = node.secondName?.text

    appendParameter(firstMember: firstMember, secondMember: secondMember, type: type)
    return .skipChildren
  }
  override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
    returnType = node.returnType.typeDescription
    return .skipChildren
  }

  fileprivate func appendParameter(firstMember: String, secondMember: String?, type: TypeDescription) {
    var parameters = self.parameters ?? []
    // Each function parameter has both an argument label and a parameter name.
    // The argument label is used when calling the function; each argument is written in the function call with its argument label before it.
    // The parameter name is used in the implementation of the function. By default, parameters use their parameter name as their argument label.
    let argumentLabel = firstMember
    let parameterName = secondMember ?? firstMember
    parameters.append(.init(argumentLabelName: argumentLabel, parameterName: parameterName, type: type))
    self.parameters = parameters
  }

  fileprivate var parameters: [FunctionDeclarationInfo.ParameterInfo]?
  fileprivate var returnType: TypeDescription?
}

public struct FunctionDeclarationInfo: Codable, Hashable {
  public let modifiers: Modifiers
  public let name: String
  public let parameters: [ParameterInfo]?
  public let returnType: TypeDescription?

  /// A convenience for creating a selector string that can be reference in Objective-C code.
  public var selectorName: String {
    "\(name)(\((parameters ?? []).map { "\($0.argumentLabelName):" }.joined()))"
  }

  public struct ParameterInfo: Codable, Hashable {
    public let argumentLabelName: String
    public let parameterName: String
    public let type: TypeDescription
  }
}
