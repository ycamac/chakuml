import Link from 'next/link'

/** Top navigation bar — update nav items as features are added. */
export function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-border bg-background/80 backdrop-blur">
      <div className="mx-auto flex h-14 max-w-screen-xl items-center justify-between px-4 sm:px-8">
        <Link href="/" className="text-subheading font-bold text-primary">
          Chaku
        </Link>
        <nav className="flex items-center gap-4 text-small text-muted-foreground">
          {/* Add nav links here */}
        </nav>
      </div>
    </header>
  )
}
