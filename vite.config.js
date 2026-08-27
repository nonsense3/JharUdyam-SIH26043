import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    open: true,
    fs: {
      // Explicitly block dev server access to all env files
      deny: ['.env', '.env.*', '*.config.js'],
    },
  },
  build: {
    // Disable source maps in production so raw files/sources are not visible in DevTools
    sourcemap: false,
  },
})
