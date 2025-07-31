import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    // Bundle analyzer - only in development
    process.env.ANALYZE && visualizer({
      filename: 'bundle-analysis.html',
      open: true,
      gzipSize: true,
      brotliSize: true,
    }),
  ].filter(Boolean),
  
  build: {
    // Enable code splitting
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor chunk for external dependencies
          vendor: ['@hotwired/turbo-rails', '@hotwired/stimulus'],
          // Mobile-specific controllers chunk
          mobile: [
            './app/javascript/controllers/mobile_menu_controller',
            './app/javascript/controllers/swipe_actions_controller', 
            './app/javascript/controllers/pull_to_refresh_controller',
            './app/javascript/controllers/long_press_controller',
            './app/javascript/controllers/touch_feedback_controller'
          ],
          // Core UI controllers chunk
          ui: [
            './app/javascript/controllers/dark_mode_controller',
            './app/javascript/controllers/notification_controller',
            './app/javascript/controllers/source_filters_controller'
          ],
          // Post management chunk
          posts: [
            './app/javascript/controllers/post_actions_controller',
            './app/javascript/controllers/virtual_scroll_controller'
          ]
        }
      }
    },
    
    // Production optimizations
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
    
    // Source maps only in development
    sourcemap: process.env.NODE_ENV === 'development',
    
    // Target modern browsers for smaller bundles
    target: 'es2020',
    
    // Enable CSS code splitting
    cssCodeSplit: true,
  },
  
  // Development optimizations
  server: {
    hmr: {
      overlay: false
    }
  }
})
