/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#131A24',
        'ink-soft': '#1D2836',
        'ink-line': '#2C3A4B',
        ash: '#48566A',
        mute: '#7B8899',
        line: '#E2E7ED',
        paper: '#EFF2F5',
        surface: '#FFFFFF',

        // brand — deep sal-forest green, the state institutional note
        brand: '#1D6E5F',
        'brand-dark': '#15544A',
        'brand-tint': '#E7F1EF',

        // role identity
        gov: '#1D6E5F',
        univ: '#4B3F9E',
        ind: '#A8641B',

        // priority
        crit: '#A4243B',
        high: '#BE6218',
        med: '#3D6B94',
        low: '#6B7A8C',
      },
      fontFamily: {
        display: ['Archivo', 'system-ui', 'sans-serif'],
        sans: ['"IBM Plex Sans"', 'system-ui', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        '2xs': ['0.6875rem', { lineHeight: '1rem' }],
      },
      letterSpacing: {
        tightest: '-0.03em',
      },
      boxShadow: {
        card: '0 1px 2px rgba(19, 26, 36, 0.04), 0 1px 3px rgba(19, 26, 36, 0.06)',
        lift: '0 4px 14px rgba(19, 26, 36, 0.10)',
      },
      keyframes: {
        rise: {
          '0%': { opacity: '0', transform: 'translateY(6px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        grow: {
          '0%': { transform: 'scaleX(0)' },
          '100%': { transform: 'scaleX(1)' },
        },
      },
      animation: {
        rise: 'rise 0.28s ease-out both',
        grow: 'grow 0.5s ease-out both',
      },
    },
  },
  plugins: [],
}
