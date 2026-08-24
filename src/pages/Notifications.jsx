import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { listNotifications, markNotificationRead, markAllNotificationsRead } from '../lib/api'
import { useAsync } from '../hooks/useAsync'
import { useTableChanges } from '../hooks/useRealtime'
import { roleMeta, timeAgo } from '../lib/constants'
import { PageHeader, Panel, LoadingBlock, ErrorNote, EmptyState } from '../components/ui'
import { IconBell, IconArrowRight } from '../components/Icons'

/** Tells the sidebar badge to recount. */
function announceChange() {
  window.dispatchEvent(new Event('notifications:changed'))
}

export default function Notifications() {
  const { role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'
  const { data, error, loading, reload } = useAsync(() => listNotifications(), [])

  useTableChanges('notifications', reload, 'notifications-page')

  const items = data ?? []
  const unread = items.filter((n) => !n.is_read).length

  // Government reads problems at /government/problems/:id, the others at
  // /university|industry/challenges/:id.
  const problemPath = (problemId) =>
    role === 'government' ? `${home}/problems/${problemId}` : `${home}/challenges/${problemId}`

  async function open(n) {
    if (n.is_read) return
    try {
      await markNotificationRead(n.id)
      announceChange()
      reload()
    } catch {
      /* not worth interrupting the user over */
    }
  }

  async function clearAll() {
    try {
      await markAllNotificationsRead()
      announceChange()
      reload()
    } catch {
      /* ignore */
    }
  }

  return (
    <>
      <PageHeader
        eyebrow={roleMeta(role)?.label}
        title="Notifications"
        description="What has changed on the reports and challenges that concern you."
        actions={
          unread ? (
            <button type="button" onClick={clearAll} className="btn-outline btn-sm">
              Mark all as read
            </button>
          ) : null
        }
      />

      <ErrorNote onRetry={reload}>{error}</ErrorNote>

      <Panel bodyClass="">
        {loading ? (
          <LoadingBlock label="Loading notifications" />
        ) : items.length ? (
          <ul>
            {items.map((n) => {
              const body = (
                <>
                  <span
                    className={`mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full ${
                      n.is_read ? 'bg-line' : 'bg-brand'
                    }`}
                    aria-hidden
                  />
                  <span className="min-w-0 flex-1">
                    <span
                      className={`block text-sm ${
                        n.is_read ? 'text-ash' : 'font-medium text-ink'
                      }`}
                    >
                      {n.title}
                    </span>
                    {n.body ? (
                      <span className="mt-0.5 block text-xs leading-relaxed text-ash">{n.body}</span>
                    ) : null}
                    <span className="mt-1 block font-mono text-2xs text-mute">
                      {timeAgo(n.created_at)}
                    </span>
                  </span>
                  {n.problem_id ? (
                    <IconArrowRight width={14} height={14} className="mt-1 shrink-0 text-line" />
                  ) : null}
                </>
              )

              return (
                <li key={n.id} className="border-b border-line last:border-b-0">
                  {n.problem_id ? (
                    <Link
                      to={problemPath(n.problem_id)}
                      onClick={() => open(n)}
                      className="flex items-start gap-3 px-5 py-4 transition-colors hover:bg-paper"
                    >
                      {body}
                    </Link>
                  ) : (
                    <button
                      type="button"
                      onClick={() => open(n)}
                      className="flex w-full items-start gap-3 px-5 py-4 text-left transition-colors hover:bg-paper"
                    >
                      {body}
                    </button>
                  )}
                </li>
              )
            })}
          </ul>
        ) : (
          <EmptyState icon={IconBell} title="Nothing to report">
            {role === 'government'
              ? 'New citizen submissions for your department, and interest from partners, will appear here.'
              : 'When a department releases a problem to you, it shows up here.'}
          </EmptyState>
        )}
      </Panel>
    </>
  )
}
