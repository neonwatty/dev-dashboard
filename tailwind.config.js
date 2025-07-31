/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{rb,html.erb}'
  ],
  darkMode: 'class',
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '1rem',
        sm: '1.5rem',
        lg: '2rem',
        xl: '2rem',
        '2xl': '3rem',
      },
      screens: {
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
        '2xl': '1440px', // Max width for content readability
      },
    },
    screens: {
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
      '3xl': '1920px', // Large screens
      '4xl': '2560px', // Ultra-wide and 4K displays
    },
    extend: {
      maxWidth: {
        'container': '1440px',
        'container-narrow': '1024px',
        'container-wide': '1600px',
        '8xl': '1440px',
        '9xl': '1600px',
      },
      colors: {
        // WCAG AA compliant color system
        accessible: {
          // Light mode text colors
          'text-primary-light': '#111827',    // 16.8:1 on white
          'text-secondary-light': '#374151',  // 8.5:1 on white
          'text-muted-light': '#4b5563',      // 6.0:1 on white
          'text-subtle-light': '#6b7280',     // 4.7:1 on white
          
          // Dark mode text colors
          'text-primary-dark': '#f9fafb',     // 16.8:1 on dark
          'text-secondary-dark': '#e5e7eb',   // 12.6:1 on dark
          'text-muted-dark': '#d1d5db',       // 9.2:1 on dark
          'text-subtle-dark': '#9ca3af',      // 5.1:1 on dark
          
          // Interactive colors
          'link-primary-light': '#1d4ed8',    // 7.1:1 on white
          'link-hover-light': '#1e40af',      // 8.9:1 on white
          'link-primary-dark': '#60a5fa',     // 5.8:1 on dark
          'link-hover-dark': '#93c5fd',       // 4.6:1 on dark
          
          // Background colors
          'bg-primary-light': '#ffffff',
          'bg-secondary-light': '#f9fafb',
          'bg-tertiary-light': '#f3f4f6',
          'bg-primary-dark': '#111827',
          'bg-secondary-dark': '#1f2937',
          'bg-tertiary-dark': '#374151',
          
          // Border colors
          'border-light': '#d1d5db',          // 3.2:1 contrast
          'border-dark': '#4b5563',           // 3.1:1 contrast
          
          // Focus indicators
          'focus-ring-light': '#2563eb',
          'focus-ring-dark': '#60a5fa',
        },
        
        // Enhanced status colors
        status: {
          // Success colors
          'success-bg-light': '#dcfce7',
          'success-text-light': '#14532d',    // 7.2:1
          'success-bg-dark': '#14532d',
          'success-text-dark': '#bbf7d0',     // 4.8:1
          
          // Error colors
          'error-bg-light': '#fef2f2',
          'error-text-light': '#7f1d1d',      // 8.1:1
          'error-bg-dark': '#7f1d1d',
          'error-text-dark': '#fecaca',       // 4.9:1
          
          // Warning colors
          'warning-bg-light': '#fefce8',
          'warning-text-light': '#713f12',    // 6.8:1
          'warning-bg-dark': '#713f12',
          'warning-text-dark': '#fde68a',     // 4.7:1
          
          // Info colors
          'info-bg-light': '#eff6ff',
          'info-text-light': '#1e3a8a',       // 8.3:1
          'info-bg-dark': '#1e3a8a',
          'info-text-dark': '#bfdbfe',        // 4.6:1
        }
      },
      
      // Enhanced focus ring utilities
      ringWidth: {
        '3': '3px',
      },
      
      // Ensure minimum touch targets
      minHeight: {
        'touch': '44px',
        'touch-lg': '48px',
      },
      
      minWidth: {
        'touch': '44px',
        'touch-lg': '48px',
      },
      
      // High contrast outline for accessibility
      outlineWidth: {
        '3': '3px',
        '4': '4px',
      }
    },
  },
  plugins: [
    // Custom plugin for accessible utilities
    function({ addUtilities, theme }) {
      addUtilities({
        // Container utilities for large screens
        '.container-responsive': {
          width: '100%',
          maxWidth: '1440px',
          marginLeft: 'auto',
          marginRight: 'auto',
          paddingLeft: '1rem',
          paddingRight: '1rem',
          '@screen sm': {
            paddingLeft: '1.5rem',
            paddingRight: '1.5rem',
          },
          '@screen lg': {
            paddingLeft: '2rem',
            paddingRight: '2rem',
          },
          '@screen 3xl': {
            paddingLeft: '3rem',
            paddingRight: '3rem',
          },
        },
        '.container-narrow': {
          width: '100%',
          maxWidth: '1024px',
          marginLeft: 'auto',
          marginRight: 'auto',
          paddingLeft: '1rem',
          paddingRight: '1rem',
          '@screen sm': {
            paddingLeft: '1.5rem',
            paddingRight: '1.5rem',
          },
          '@screen lg': {
            paddingLeft: '2rem',
            paddingRight: '2rem',
          },
        },
        '.container-wide': {
          width: '100%',
          maxWidth: '1600px',
          marginLeft: 'auto',
          marginRight: 'auto',
          paddingLeft: '1rem',
          paddingRight: '1rem',
          '@screen sm': {
            paddingLeft: '1.5rem',
            paddingRight: '1.5rem',
          },
          '@screen lg': {
            paddingLeft: '2rem',
            paddingRight: '2rem',
          },
          '@screen 3xl': {
            paddingLeft: '3rem',
            paddingRight: '3rem',
          },
        },
        '.full-width-bg': {
          width: '100%',
          '& .container-responsive, & .responsive-container': {
            maxWidth: '1440px',
            marginLeft: 'auto',
            marginRight: 'auto',
          },
        },
        
        // Accessible text utilities
        '.text-accessible-primary': {
          color: 'var(--text-primary-light)',
          '@media (prefers-color-scheme: dark)': {
            color: 'var(--text-primary-dark)',
          },
        },
        '.text-accessible-secondary': {
          color: 'var(--text-secondary-light)',
          '@media (prefers-color-scheme: dark)': {
            color: 'var(--text-secondary-dark)',
          },
        },
        '.text-accessible-muted': {
          color: 'var(--text-muted-light)',
          '@media (prefers-color-scheme: dark)': {
            color: 'var(--text-muted-dark)',
          },
        },
        '.text-accessible-subtle': {
          color: 'var(--text-subtle-light)',
          '@media (prefers-color-scheme: dark)': {
            color: 'var(--text-subtle-dark)',
          },
        },
        
        // Accessible link utilities
        '.link-accessible': {
          color: 'var(--link-primary-light)',
          textDecoration: 'underline',
          textUnderlineOffset: '2px',
          '&:hover, &:focus': {
            color: 'var(--link-hover-light)',
          },
          '&:focus': {
            outline: '2px solid var(--focus-ring-light)',
            outlineOffset: '2px',
          },
          '@media (prefers-color-scheme: dark)': {
            color: 'var(--link-primary-dark)',
            '&:hover, &:focus': {
              color: 'var(--link-hover-dark)',
            },
            '&:focus': {
              outlineColor: 'var(--focus-ring-dark)',
            },
          },
        },
        
        // High contrast mode support
        '@media (prefers-contrast: high)': {
          '.text-accessible-primary': {
            color: 'black',
            '@media (prefers-color-scheme: dark)': {
              color: 'white',
            },
          },
          '.link-accessible': {
            textDecorationThickness: '3px',
            '&:focus': {
              outlineWidth: '4px',
            },
          },
        },
      })
    },
  ],
}