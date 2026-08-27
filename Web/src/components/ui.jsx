import { statusMeta, priorityMeta, scopeMeta } from '../lib/constants'
import { IconPin, IconAlert, IconExternal } from './Icons'

/* ------------------------------------------------------------------- chips */

export function StatusChip({ value, className = '' }) {
  const meta = statusMeta(value)
  return (
    <span className={`chip ${meta.className} ${className}`} title={meta.description}>
      <span className={`h-1.5 w-1.5 rounded-full ${meta.dot}`} />
      {meta.label}
    </span>
  )
}

export function PriorityChip({ value, className = '' }) {
  const meta = priorityMeta(value)
  return <span className={`chip ${meta.className} ${className}`}>{meta.label}</span>
}

export function ScopeChip({ value, className = '' }) {
  const meta = scopeMeta(value)
  return <span className={`chip ${meta.className} ${className}`}>{meta.label}</span>
}

export function CategoryChip({ value, className = '' }) {
  if (!value) return null
  return (
    <span className={`chip border-line bg-paper text-ash normal-case tracking-normal ${className}`}>
      {value}
    </span>
  )
}

/* --------------------------------------------------------------- structure */

export function PageHeader({ eyebrow, title, description, actions }) {
  return (
    <header className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div className="min-w-0">
        {eyebrow ? <p className="eyebrow mb-1.5">{eyebrow}</p> : null}
        <h1 className="text-2xl font-semibold tracking-tightest text-ink sm:text-[1.75rem]">
          {title}
        </h1>
        {description ? <p className="mt-1.5 max-w-2xl text-sm text-ash">{description}</p> : null}
      </div>
      {actions ? <div className="flex shrink-0 items-center gap-2">{actions}</div> : null}
    </header>
  )
}

export function Panel({ title, subtitle, actions, children, className = '', bodyClass = 'p-5' }) {
  return (
    <section className={`card ${className}`}>
      {title || actions ? (
        <div className="flex items-center justify-between gap-3 border-b border-line px-5 py-3.5">
          <div className="min-w-0">
            <h2 className="text-sm font-semibold text-ink">{title}</h2>
            {subtitle ? <p className="mt-0.5 text-xs text-mute">{subtitle}</p> : null}
          </div>
          {actions ? <div className="flex shrink-0 items-center gap-2">{actions}</div> : null}
        </div>
      ) : null}
      <div className={bodyClass}>{children}</div>
    </section>
  )
}

/** A labelled read-only value, used across the problem detail screens. */
export function DataRow({ label, children, mono = false }) {
  return (
    <div className="border-b border-line py-2.5 last:border-b-0">
      <dt className="eyebrow mb-1">{label}</dt>
      <dd className={`text-sm text-ink ${mono ? 'font-mono text-xs' : ''}`}>{children ?? '—'}</dd>
    </div>
  )
}

/* ----------------------------------------------------------------- states */

export function Spinner({ className = 'h-4 w-4' }) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={`inline-block animate-spin rounded-full border-2 border-current border-t-transparent ${className}`}
    />
  )
}

export function LoadingBlock({ label = 'Loading' }) {
  return (
    <div className="flex items-center justify-center gap-2.5 py-16 text-sm text-mute">
      <Spinner />
      {label}
    </div>
  )
}

export function EmptyState({ icon: Icon, title, children, action }) {
  return (
    <div className="flex flex-col items-center justify-center px-6 py-14 text-center">
      {Icon ? (
        <span className="mb-3 flex h-10 w-10 items-center justify-center rounded-full border border-line bg-paper text-mute">
          <Icon />
        </span>
      ) : null}
      <p className="text-sm font-semibold text-ink">{title}</p>
      {children ? <p className="mt-1.5 max-w-sm text-sm text-ash">{children}</p> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  )
}

export function ErrorNote({ children, onRetry }) {
  if (!children) return null
  return (
    <div className="flex items-start gap-3 rounded-md border border-crit/25 bg-crit/5 px-4 py-3 text-sm text-crit">
      <IconAlert className="mt-0.5 shrink-0" />
      <div className="min-w-0 flex-1">
        <p>{children}</p>
        {onRetry ? (
          <button type="button" onClick={onRetry} className="mt-2 text-xs font-semibold underline">
            Try again
          </button>
        ) : null}
      </div>
    </div>
  )
}

/* --------------------------------------------------------------- location */

export function LocationLine({ address, latitude, longitude, showLink = true }) {
  const hasCoords = Number.isFinite(latitude) && Number.isFinite(longitude)
  const mapUrl = hasCoords ? `https://www.google.com/maps?q=${latitude},${longitude}` : null

  return (
    <div className="space-y-1.5">
      <p className="flex items-start gap-2 text-sm text-ink">
        <IconPin className="mt-0.5 shrink-0 text-mute" />
        <span>{address || 'No street address recorded'}</span>
      </p>
      {hasCoords ? (
        <p className="pl-6 font-mono text-2xs text-mute">
          {latitude.toFixed(5)}, {longitude.toFixed(5)}
          {showLink && mapUrl ? (
            <>
              {' · '}
              <a
                href={mapUrl}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1 text-brand hover:underline"
              >
                Open in Maps
                <IconExternal width={11} height={11} />
              </a>
            </>
          ) : null}
        </p>
      ) : null}
    </div>
  )
}
