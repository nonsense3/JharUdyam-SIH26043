import { Link } from 'react-router-dom'
import { priorityMeta, timeAgo } from '../lib/constants'
import { PriorityChip, CategoryChip, StatusChip } from './ui'
import ProblemImage from './ProblemImage'
import { IconPin, IconCheck } from './Icons'

/**
 * A released challenge, as a university or industry representative sees it.
 * Cards rather than a table, because this screen is for browsing and choosing.
 */
export default function ProblemCard({ problem, to, interested = false }) {
  return (
    <Link
      to={to}
      className="card group flex flex-col overflow-hidden transition-shadow hover:shadow-lift focus-visible:rounded-lg"
    >
      <div className="relative">
        <ProblemImage
          src={problem.image_url}
          alt={problem.title}
          ratio="aspect-[16/9]"
          className="rounded-none border-0 border-b border-line"
        />
        <span
          className={`absolute left-0 top-0 h-full w-1 ${priorityMeta(problem.priority).bar}`}
          aria-hidden
        />
        {interested ? (
          <span className="absolute right-2.5 top-2.5 inline-flex items-center gap-1 rounded bg-surface/95 px-2 py-1 font-mono text-2xs uppercase tracking-[0.1em] text-brand-dark shadow-card backdrop-blur">
            <IconCheck width={11} height={11} />
            Interest sent
          </span>
        ) : null}
      </div>

      <div className="flex flex-1 flex-col p-4">
        <div className="flex items-center justify-between gap-2">
          <span className="ticket">{problem.ticket_no ?? '—'}</span>
          <span className="font-mono text-2xs text-mute">
            {problem.released_at
              ? `Released ${timeAgo(problem.released_at)}`
              : timeAgo(problem.created_at)}
          </span>
        </div>

        <h3 className="mt-2 line-clamp-2 text-sm font-semibold leading-snug text-ink transition-colors group-hover:text-brand-dark">
          {problem.title || 'Untitled challenge'}
        </h3>

        <p className="mt-1.5 line-clamp-2 text-xs leading-relaxed text-ash">{problem.description}</p>

        <p className="mt-3 flex items-start gap-1.5 text-xs text-mute">
          <IconPin width={13} height={13} className="mt-0.5 shrink-0" />
          <span className="line-clamp-1">{problem.address || 'Coordinates only'}</span>
        </p>

        <div className="mt-3 flex flex-wrap items-center gap-1.5 border-t border-line pt-3">
          <PriorityChip value={problem.priority} />
          <CategoryChip value={problem.category} />
          <StatusChip value={problem.status} className="ml-auto" />
        </div>
      </div>
    </Link>
  )
}
