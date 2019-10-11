import Commandant
import Foundation

let registry = CommandRegistry<Error>()

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
  fputs("\(error)\n", stderr)
}
