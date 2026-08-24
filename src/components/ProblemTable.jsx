import { useNavigate } from 'react-router-dom'
import { priorityMeta, timeAgo } from '../lib/constants'
import { StatusChip, PriorityChip } from './ui'
import { IconArrowRight } from './Icons'

/**
 * The department queue. A table rather than cards, because a government user
 * is triaging a list, not browsing.
 */
export default function ProblemTable({ problems, basePath, emptyState }) {
  const navigate = useNavigate()

  if (!problems?.length) return emptyState ?? null

  return (
    <div className="thin-scroll overflow-x-auto">
      <table className="w-full min-w-[760px] border-collapse">
        <thead>
          <tr>
            <th className="th w-[104px]">Ref</th>
            <th className="th">Problem</th>
            <th className="th w-[168px]">Location</th>
            <th className="th w-[96px]">Priority</th>
            <th className="th w-[150px]">Status</th>
            <th className="th w-[92px]">Reported</th>
            <th className="th w-[44px]" aria-label="Open" />
          </tr>
        </thead>
        <tbody>
          {problems.map((p) => {
            const href = `${basePath}/${p.id}`
            return (
              <tr
                key={p.id}
                onClick={() => navigate(href)}
                className="group cursor-pointer transition-colors hover:bg-paper"
              >
                <td className="td">
                  <div className="flex items-start gap-2">
                    <span
                      className={`mt-1 h-3.5 w-0.5 shrink-0 rounded ${priorityMeta(p.priority).bar}`}
                      aria-hidden
                    />
                    <span className="ticket">{p.ticket_no ?? '—'}</span>
                  </div>
                </td>

                <td className="td">
                  <p className="line-clamp-2 font-medium text-ink">{p.title || 'Untitled report'}</p>
                  {p.category ? (
                    <p className="mt-1 font-mono text-2xs uppercase tracking-[0.08em] text-mute">
                      {p.category}
                    </p>
                  ) : null}
                </td>

                <td className="td">
                  <p className="line-clamp-2 text-xs text-ash">{p.address || 'Coordinates only'}</p>
                </td>

                <td className="td">
                  <PriorityChip value={p.priority} />
                </td>

                <td className="td">
                  <StatusChip value={p.status} />
                </td>

                <td className="td">
                  <span className="whitespace-nowrap font-mono text-2xs text-mute">
                    {timeAgo(p.created_at)}
                  </span>
                </td>

                <td className="td text-right">
                  <IconArrowRight
                    width={15}
                    height={15}
                    className="text-line transition-colors group-hover:text-brand"
                  />
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
