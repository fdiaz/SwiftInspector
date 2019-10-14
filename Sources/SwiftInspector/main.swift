import Commandant
import Foundation
import SwiftInspectorKit

let registry = CommandRegistry<Error>()
registry.register(TypeConformanceCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
  // Using fputs instead of print to log to standard error
  fputs("\(error)\n", stderr)
}
