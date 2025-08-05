// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Manually import our post actions controller for now
import PostActionsController from "./post_actions_controller"
application.register("post-actions", PostActionsController)

console.log("🎯 PostActionsController registered manually!")
