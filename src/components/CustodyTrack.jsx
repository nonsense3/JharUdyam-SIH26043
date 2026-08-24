// ---------------------------------------------------------------------------
// The custody track: where a report currently sits, and whose hands it is in.
//
// This is the one place the whole workflow is visible at a glance, so it is
// drawn from the real status rather than a decorative stepper — a problem the
// department keeps in-house never shows the collaboration steps at all.
// ---------------------------------------------------------------------------

const COLLAB_STEPS = [
  { key: 'reported', label: 'Reported', hint: 'Citizen' },
  { key: 'review', label: 'Dept. review', hint: 'Government' },
  { key: 'released', label: 'Released', hint: 'Government' },
  { key: 'interest', label: 'Interest', hint: 'Partner' },
  { key: 'progress', label: 'In progress', hint: 'Partner' },
  { key: 'resolved', label: 'Resolved', hint: '' },
]

const INTERNAL_STEPS = [
  { key: 'reported', label: 'Reported', hint: 'Citizen' },
  { key: 'review', label: 'Dept. review', hint: 'Government' },
  { key: 'internal', label: 'Kept in-house', hint: 'Government' },
  { key: 'progress', label: 'In progress', hint: 'Government' },
  { key: 'resolved', label: 'Resolved', hint: '' },
]

const COLLAB_INDEX = {
  submitted: 0,
  under_review: 1,
  released: 2,
  interest_expressed: 3,
  in_progress: 4,
  resolved: 5,
}

const INTERNAL_INDEX = {
  government_handling: 2,
  in_progress: 3,
  resolved: 4,
}

export default function CustodyTrack({ status, className = '' }) {
  const internal = status === 'government_handling' || status === 'internal'
  const steps = internal ? INTERNAL_STEPS : COLLAB_STEPS
  const reached = internal
    ? (INTERNAL_INDEX[status] ?? 2)
    : (COLLAB_INDEX[status] ?? 0)

  return (
    <div className={`thin-scroll overflow-x-auto ${className}`}>
      <ol className="flex min-w-[520px] items-start">
        {steps.map((step, i) => {
          const done = i < reached
          const current = i === reached
          const future = i > reached
          const isLast = i === steps.length - 1

          return (
            <li key={step.key} className="flex min-w-0 flex-1 flex-col gap-2">
              <div className="flex items-center">
                <span
                  className={[
                    'h-2.5 w-2.5 shrink-0 rotate-45 border transition-colors',
                    done && 'border-brand bg-brand',
                    current && 'border-brand bg-surface ring-2 ring-brand/25',
                    future && 'border-line bg-surface',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                />
                {!isLast ? (
                  <span
                    className={`ml-1 h-px flex-1 origin-left animate-grow ${
                      done ? 'bg-brand' : 'bg-line'
                    }`}
                  />
                ) : null}
              </div>

              <div className="pr-3">
                <p
                  className={`font-mono text-2xs uppercase tracking-[0.1em] ${
                    future ? 'text-mute' : 'text-ink'
                  } ${current ? 'font-medium' : ''}`}
                >
                  {step.label}
                </p>
                {step.hint ? (
                  <p className="mt-0.5 text-2xs text-mute">{current ? `Now · ${step.hint}` : step.hint}</p>
                ) : null}
              </div>
            </li>
          )
        })}
      </ol>
    </div>
  )
}
