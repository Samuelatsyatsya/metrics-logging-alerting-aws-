import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    // ALB target health checks use the target IP/port as Host header,
    // so allow all hosts when running the dev server inside ECS.
    allowedHosts: true,
    proxy: {
      '/api/v1': {
        target: 'http://127.0.0.1:5000',
        changeOrigin: true
      }
    }
  }
})
