import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import {
  getProblem,
  listInterestsForProblem,
  expressInterest,
  withdrawInterest,
} from '../../lib/api'
import { useAsync } from '../../hooks/useAsync'
import { roleMeta, formatDateTime, statusMeta } from '../../lib/constants'
import {
  PageHeader,
  Panel,
  DataRow,
  LoadingBlock,
  ErrorNote,
  StatusChip,
  PriorityChip,
  CategoryChip,
  LocationLine,
  Spinner,
} from '../../components/ui'
import CustodyTrack from '../../components/CustodyTrack'
import ProblemImage from '../../components/ProblemImage'
import { IconArrowLeft, IconCheck, IconHand } from '../../components/Icons'

export default function CollabChallengeDetail() {
  const { id } = useParams()
  const { profile, role } = useAuth()
  const home = roleMeta(role)?.home ?? '/'

  const problemQuery = useAsync(() => getProblem(id), [id])
  // Row level security means an organisation only gets its own interest back.
  const interestQuery = useAsync(() => listInterestsForProblem(id), [id])

  const [note, setNote] = useState('')
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState(null)

  const problem = problemQuery.data
  const myInterest = (interestQuery.data ?? []).find((it) => it.org_id === profile?.id) ?? null

  async function send() {
    setBusy(true)
    setActionError(null)
    try {
      await expressInterest({ problemId: id, profile, note })
      await interestQuery.reload()
      await problemQuery.reload()
      setNote('')
    } catch (err) {
      setActionError(
        /duplicate key/i.test(err?.message ?? '')
          ? 'Your organisation has already registered interest in this challenge.'
          : (err?.message ?? 'Interest could not be sent.')
      )
    } finally {
      setBusy(false)
    }
  }

  async function withdraw() {
    if (!myInterest) return
    setBusy(true)
    setActionError(null)
    try {
      await withdrawInterest(myInterest.id)
      await interestQuery.reload()
      await problemQuery.reload()
    } catch (err) {
      setActionError(err?.message ?? 'Interest could not be withdrawn.')
    } finally {
      setBusy(false)
    }
  }

  if (problemQuery.loading) return <LoadingBlock label="Opening challenge" />

  if (problemQuery.error || !problem) {
    return (
      <>
        <BackLink home={home} />
        <ErrorNote onRetry={problemQuery.reload}>
          {problemQuery.error ??
            'This challenge is no longer open to you. The department may have withdrawn it.'}
        </ErrorNote>
      </>
    )
  }

  const orgName = profile?.organization || profile?.full_name || 'Your organisation'

  return (
    <>
      <BackLink home={home} />

      <PageHeader
        eyebrow={`${problem.ticket_no ?? 'Challenge'} · released by ${problem.department ?? 'government'}`}
        title={problem.title || 'Untitled challenge'}
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <PriorityChip value={problem.priority} />
            <StatusChip value={problem.status} />
          </div>
        }
      />

      <div className="card mb-6 px-5 py-4">
        <CustodyTrack status={problem.status} />
      </div>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)]">
        <div className="space-y-5">
          <Panel title="What the citizen reported">
            <ProblemImage src={problem.image_url} alt={problem.title} />
            <p className="mt-4 whitespace-pre-line text-sm leading-relaxed text-ink">
              {problem.description || 'No description was recorded for this report.'}
            </p>
            <div className="mt-4 flex flex-wrap gap-2">
              <CategoryChip value={problem.category} />
            </div>
            <div className="mt-5 border-t border-line pt-4">
              <p className="eyebrow mb-2">Location</p>
              <LocationLine
                address={problem.address}
                latitude={problem.latitude}
                longitude={problem.longitude}
              />
            </div>
          </Panel>

          {problem.government_note ? (
            <Panel title="Note from the department">
              <p className="whitespace-pre-line text-sm leading-relaxed text-ink">
                {problem.government_note}
              </p>
            </Panel>
          ) : null}
        </div>

        <div className="space-y-5 lg:sticky lg:top-6 lg:self-start">
          <Panel
            title={myInterest ? 'Your interest is registered' : 'Take this on'}
            subtitle={
              myInterest
                ? undefined
                : 'Nobody is assigning this to you. Tell the department if you want to work on it.'
            }
          >
            {myInterest ? (
              <>
                <p className="flex items-start gap-2 text-sm text-ink">
                  <IconCheck width={16} height={16} className="mt-0.5 shrink-0 text-brand" />
                  <span>
                    {orgName} told the {problem.department ?? 'department'} it wants to work on this
                    on {formatDateTime(myInterest.created_at)}.
                  </span>
                </p>
                {myInterest.note ? (
                  <p className="mt-3 rounded-md border border-line bg-paper px-3.5 py-3 text-sm text-ash">
                    “{myInterest.note}”
                  </p>
                ) : null}

                <ErrorNote>{actionError}</ErrorNote>

                <button
                  type="button"
                  onClick={withdraw}
                  disabled={busy}
                  className="btn-outline mt-4 w-full"
                >
                  {busy ? <Spinner /> : null}
                  Withdraw interest
                </button>
              </>
            ) : (
              <>
                <label htmlFor="pitch" className="field-label">
                  How you would approach it{' '}
                  <span className="normal-case tracking-normal">(optional)</span>
                </label>
                <textarea
                  id="pitch"
                  rows={4}
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder={
                    role === 'university'
                      ? 'Which department or lab would take this, and what could students contribute?'
                      : 'What capability or resource could your company bring to this?'
                  }
                  className="input resize-y"
                />

                <ErrorNote>{actionError}</ErrorNote>

                <button type="button" onClick={send} disabled={busy} className="btn-primary mt-4 w-full">
                  {busy ? <Spinner /> : <IconHand width={15} height={15} />}
                  {busy ? 'Sending' : 'Express interest'}
                </button>
                <p className="mt-2.5 text-xs text-mute">
                  The department will see {orgName} on this report. You can withdraw at any time.
                </p>
              </>
            )}
          </Panel>

          <Panel title="Challenge details">
            <dl>
              <DataRow label="Reference" mono>
                {problem.ticket_no}
              </DataRow>
              <DataRow label="Owning department">{problem.department ?? 'Unassigned'}</DataRow>
              <DataRow label="Category">{problem.category ?? 'Uncategorised'}</DataRow>
              <DataRow label="Released" mono>
                {formatDateTime(problem.released_at)}
              </DataRow>
              <DataRow label="Reported" mono>
                {formatDateTime(problem.created_at)}
              </DataRow>
              <DataRow label="Where it stands">{statusMeta(problem.status).description}</DataRow>
            </dl>
          </Panel>
        </div>
      </div>
    </>
  )
}

function BackLink({ home }) {
  return (
    <Link
      to={`${home}/challenges`}
      className="mb-4 inline-flex items-center gap-2 font-mono text-2xs uppercase tracking-[0.12em] text-mute transition-colors hover:text-ink"
    >
      <IconArrowLeft width={14} height={14} />
      Open challenges
    </Link>
  )
}
