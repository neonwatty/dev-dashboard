// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Manually import our controllers
import PostActionsController from "./post_actions_controller"
import DarkModeController from "./dark_mode_controller"

// Register controllers
application.register("post-actions", PostActionsController)
application.register("dark-mode", DarkModeController)

console.log("🎯 PostActionsController registered:", application.router.controllerAttribute)
console.log("🌙 DarkModeController registered:", application.router.controllerAttribute)
console.log("📝 All registered controllers:", Object.keys(application.router.modulesByIdentifier))
