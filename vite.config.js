import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'serve-landing-at-root',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          if (req.url === '/' || req.url === '') {
            req.url = '/landing.html'
          }
          next()
        })
      },
      configurePreviewServer(server) {
        server.middlewares.use((req, res, next) => {
          if (req.url === '/' || req.url === '') {
            req.url = '/landing.html'
          }
          next()
        })
      },
    },
  ],
  server: {
    port: 5173,
    open: true,
    fs: {
      deny: ['.env', '.env.*', '*.config.js'],
    },
  },
  build: {
    sourcemap: false,
  },
})
