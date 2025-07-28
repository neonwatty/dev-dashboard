// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Manually import our controllers
import PostActionsController from "./post_actions_controller"
import DarkModeController from "./dark_mode_controller"
import MobileMenuController from "./mobile_menu_controller"
import SwipeActionsController from "./swipe_actions_controller"
import PullToRefreshController from "./pull_to_refresh_controller"
import LongPressController from "./long_press_controller"
import TouchFeedbackController from "./touch_feedback_controller"

// Register controllers
application.register("post-actions", PostActionsController)
application.register("dark-mode", DarkModeController)
application.register("mobile-menu", MobileMenuController)
application.register("swipe-actions", SwipeActionsController)
application.register("pull-to-refresh", PullToRefreshController)
application.register("long-press", LongPressController)
application.register("touch-feedback", TouchFeedbackController)

console.log("🎯 PostActionsController registered:", application.router.controllerAttribute)
console.log("🌙 DarkModeController registered:", application.router.controllerAttribute)
console.log("📱 MobileMenuController registered:", application.router.controllerAttribute)
console.log("👆 Touch controllers registered:", ["swipe-actions", "pull-to-refresh", "long-press"])
console.log("📝 All registered controllers:", Object.keys(application.router.modulesByIdentifier))
