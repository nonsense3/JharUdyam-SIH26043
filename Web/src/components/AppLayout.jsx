import { useEffect, useState } from 'react'
import { Link, NavLink, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { supabase } from '../lib/supabase'
import { roleMeta } from '../lib/constants'
import { IconGrid, IconList, IconBell, IconUser, IconLogout, IconHand, roleIcon } from './Icons'
import logoImg from '../assets/logo.jpeg'

/** Sidebar entries per role. `to` values are relative to the role's home path. */
function navFor(role, home) {
  if (role === 'government') {
    return [
      { to: home, label: 'Dashboard', icon: IconGrid, end: true },
      { to: `${home}/problems`, label: 'Problems', icon: IconList },
      { to: `${home}/notifications`, label: 'Notifications', icon: IconBell, badge: true },
      { to: `${home}/profile`, label: 'Profile', icon: IconUser },
    ]
  }
  return [
    { to: home, label: 'Dashboard', icon: IconGrid, end: true },
    { to: `${home}/challenges`, label: 'Open challenges', icon: IconList },
    { to: `${home}/interests`, label: 'Our interests', icon: IconHand },
    { to: `${home}/notifications`, label: 'Notifications', icon: IconBell, badge: true },
    { to: `${home}/profile`, label: 'Profile', icon: IconUser },
  ]
}

export default function AppLayout({ children }) {
  const { profile, role, signOut } = useAuth()
  const location = useLocation()
  const [unread, setUnread] = useState(0)
  const [drawerOpen, setDrawerOpen] = useState(false)

  const meta = roleMeta(role)
  const home = meta?.home ?? '/'
  const items = navFor(role, home)
  const RoleIcon = roleIcon[role] ?? IconUser

  // Unread badge: refresh on navigation, on a live insert, and when a page
  // tells us it changed something.
  useEffect(() => {
    let cancelled = false

    async function load() {
      const { count, error } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('is_read', false)
      if (!cancelled && !error) setUnread(count ?? 0)
    }

    load()
    const onChange = () => load()
    window.addEventListener('notifications:changed', onChange)

    const channel = supabase
      .channel('notification-badge')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'notifications' }, load)
      .subscribe()

    return () => {
      cancelled = true
      window.removeEventListener('notifications:changed', onChange)
      supabase.removeChannel(channel)
    }
  }, [location.pathname])

  useEffect(() => setDrawerOpen(false), [location.pathname])

  const sidebar = (
    <div className="flex h-full flex-col bg-ink text-white">
      {/* brand */}
      <Link to={home} className="flex items-center gap-3 px-5 py-5">
        <img
          src={logoImg}
          alt="JharUdyam Logo"
          className="h-9 w-9 shrink-0 rounded-md object-contain bg-white/10 p-0.5"
        />
        <span className="min-w-0">
          <span className="block font-display text-[0.95rem] font-semibold leading-tight tracking-tight">
            JharUdyam
          </span>
          <span className="block font-mono text-2xs uppercase tracking-[0.14em] text-white/45">
            Challenge platform
          </span>
        </span>
      </Link>

      {/* which portal am I in */}
      <div className="mx-5 mb-5 rounded-md border border-white/10 bg-white/[0.04] px-3.5 py-3">
        <div className="flex items-center gap-2">
          <RoleIcon width={15} height={15} className={meta?.accent ?? 'text-white'} />
          <p className="font-mono text-2xs uppercase tracking-[0.14em] text-white/60">
            {meta?.label ?? 'Portal'}
          </p>
        </div>
        <p className="mt-1.5 truncate text-sm font-medium text-white">
          {profile?.role === 'government'
            ? profile?.department || 'All departments'
            : profile?.organization || 'Organisation'}
        </p>
      </div>

      <nav className="thin-scroll flex-1 overflow-y-auto px-3">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            className={({ isActive }) =>
              [
                'mb-0.5 flex items-center gap-3 rounded-md px-2.5 py-2 text-sm transition-colors',
                isActive
                  ? 'bg-white/10 font-medium text-white'
                  : 'text-white/60 hover:bg-white/5 hover:text-white',
              ].join(' ')
            }
          >
            <item.icon width={16} height={16} />
            <span className="flex-1">{item.label}</span>
            {item.badge && unread > 0 ? (
              <span className="rounded-full bg-brand px-1.5 py-0.5 font-mono text-2xs font-medium leading-none text-white">
                {unread > 99 ? '99+' : unread}
              </span>
            ) : null}
          </NavLink>
        ))}
      </nav>

      {/* who am I */}
      <div className="border-t border-white/10 px-5 py-4">
        <p className="truncate text-sm font-medium text-white">{profile?.full_name || 'Signed in'}</p>
        <p className="mt-0.5 truncate font-mono text-2xs text-white/45">{meta?.tagline}</p>
        <button
          type="button"
          onClick={signOut}
          className="mt-3 flex w-full items-center gap-2 rounded-md border border-white/10 px-2.5 py-1.5 text-xs text-white/70 transition-colors hover:border-white/25 hover:text-white"
        >
          <IconLogout width={14} height={14} />
          Sign out
        </button>
      </div>
    </div>
  )

  return (
    <div className="min-h-screen lg:flex">
      {/* desktop sidebar */}
      <aside className="hidden w-64 shrink-0 lg:sticky lg:top-0 lg:block lg:h-screen">{sidebar}</aside>

      {/* mobile drawer */}
      {drawerOpen ? (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button
            type="button"
            aria-label="Close menu"
            onClick={() => setDrawerOpen(false)}
            className="absolute inset-0 bg-ink/50"
          />
          <div className="absolute left-0 top-0 h-full w-72 shadow-lift">{sidebar}</div>
        </div>
      ) : null}

      <div className="min-w-0 flex-1">
        {/* mobile top bar */}
        <div className="sticky top-0 z-30 flex items-center justify-between border-b border-line bg-surface/95 px-4 py-3 backdrop-blur lg:hidden">
          <button type="button" onClick={() => setDrawerOpen(true)} className="btn-outline btn-sm">
            Menu
          </button>
          <div className="flex items-center gap-2">
            <img src={logoImg} alt="JharUdyam" className="h-6 w-6 rounded object-contain" />
            <span className="font-display text-sm font-semibold">JharUdyam</span>
          </div>
          <span className={`chip ${meta ? 'border-line bg-paper text-ash' : ''}`}>
            {meta?.label ?? ''}
          </span>
        </div>

        <main className="mx-auto w-full max-w-[1200px] animate-rise px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
          {children}
        </main>
      </div>
    </div>
  )
}
