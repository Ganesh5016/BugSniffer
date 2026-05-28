/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        cyber: {
          bg: '#030712',
          surface: '#0f172a',
          card: '#111827',
          border: '#1e3a5f',
          blue: '#00d4ff',
          green: '#00ff88',
          red: '#ff4444',
          yellow: '#ffd700',
          purple: '#7c3aed',
          muted: '#374151'
        }
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
        display: ['Orbitron', 'monospace'],
        body: ['Inter', 'sans-serif']
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
        'scan-line': 'scanLine 2s linear infinite',
        'float': 'float 3s ease-in-out infinite',
      },
      keyframes: {
        glow: {
          'from': { boxShadow: '0 0 5px #00d4ff, 0 0 10px #00d4ff' },
          'to': { boxShadow: '0 0 20px #00d4ff, 0 0 40px #00d4ff' }
        },
        scanLine: {
          '0%': { top: '0%' },
          '100%': { top: '100%' }
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' }
        }
      },
      backgroundImage: {
        'cyber-grid': "linear-gradient(rgba(0, 212, 255, 0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0, 212, 255, 0.03) 1px, transparent 1px)",
        'glow-blue': 'radial-gradient(circle, rgba(0,212,255,0.15) 0%, transparent 70%)',
        'glow-green': 'radial-gradient(circle, rgba(0,255,136,0.15) 0%, transparent 70%)',
      }
    }
  },
  plugins: []
}
