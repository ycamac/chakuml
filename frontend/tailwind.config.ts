import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{ts,tsx}',
    './src/components/**/*.{ts,tsx}',
    './src/app/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: { '2xl': '1400px' },
    },
    extend: {
      // All colors reference CSS variables defined in globals.css.
      // Change the variables once — the whole UI updates.
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
      },
      // Single type scale — use these classes everywhere, never arbitrary sizes.
      fontSize: {
        'display':    ['3rem',      { lineHeight: '1.1', fontWeight: '700' }],
        'heading':    ['1.5rem',    { lineHeight: '1.3', fontWeight: '600' }],
        'subheading': ['1.125rem',  { lineHeight: '1.4', fontWeight: '600' }],
        'body':       ['0.9375rem', { lineHeight: '1.6', fontWeight: '400' }],
        'small':      ['0.8125rem', { lineHeight: '1.5', fontWeight: '400' }],
        'label':      ['0.75rem',   { lineHeight: '1.4', fontWeight: '500', letterSpacing: '0.05em' }],
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}

export default config
