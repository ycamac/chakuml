import { cn } from '@/lib/utils'

interface PageWrapperProps {
  children: React.ReactNode
  className?: string
}

/** Full-height page container with consistent max-width and padding. */
export function PageWrapper({ children, className }: PageWrapperProps) {
  return (
    <div className={cn('mx-auto w-full max-w-screen-xl px-4 py-8 sm:px-8', className)}>
      {children}
    </div>
  )
}
