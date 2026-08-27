// Shown when .env has no Supabase keys yet. Better than a blank page and a
// console error for someone who has never used Supabase before.

const STEPS = [
  {
    title: 'Create a Supabase project',
    body: 'Go to supabase.com, sign in with GitHub, and create a new project. Save the database password somewhere — you will not be shown it again.',
  },
  {
    title: 'Run the SQL files',
    body: 'In your project: SQL Editor → New query. Paste and run supabase/schema.sql, then setup_users.sql, then seed.sql.',
  },
  {
    title: 'Copy your two keys',
    body: 'Project Settings → API. Copy the Project URL and the anon public key.',
  },
  {
    title: 'Create a .env file',
    body: 'In this project folder, copy .env.example to .env, paste the two values in, then restart npm run dev.',
  },
]

export default function SetupNeeded() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-paper px-4 py-12">
      <div className="w-full max-w-xl">
        <div className="mb-6 flex items-center gap-3">
          <span className="flex h-9 w-9 items-center justify-center rounded-md bg-brand font-display text-base font-bold text-white">
            JU
          </span>
          <div>
            <p className="font-display text-[0.95rem] font-semibold leading-tight text-ink">
              JharUdyam
            </p>
            <p className="font-mono text-2xs uppercase tracking-[0.14em] text-mute">
              Setup required
            </p>
          </div>
        </div>

        <div className="card p-7">
          <h1 className="text-lg font-semibold text-ink">Connect your Supabase project</h1>
          <p className="mt-1.5 text-sm text-ash">
            The portal needs a database before it can sign anyone in. The full walkthrough is in{' '}
            <code className="rounded bg-paper px-1.5 py-0.5 font-mono text-xs">
              SUPABASE_SETUP.md
            </code>
            .
          </p>

          <ol className="mt-6 space-y-0">
            {STEPS.map((step, i) => (
              <li key={step.title} className="flex gap-4">
                <div className="flex flex-col items-center pt-1">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border border-line bg-paper font-mono text-2xs text-ash">
                    {i + 1}
                  </span>
                  {i < STEPS.length - 1 ? <span className="my-1 w-px flex-1 bg-line" /> : null}
                </div>
                <div className="pb-5">
                  <p className="text-sm font-medium text-ink">{step.title}</p>
                  <p className="mt-1 text-sm leading-relaxed text-ash">{step.body}</p>
                </div>
              </li>
            ))}
          </ol>

          <div className="rounded-md border border-line bg-ink px-4 py-3.5 font-mono text-xs leading-relaxed text-white/80">
            <span className="text-white/40"># .env</span>
            <br />
            VITE_SUPABASE_URL=<span className="text-white/40">https://xxxx.supabase.co</span>
            <br />
            VITE_SUPABASE_ANON_KEY=<span className="text-white/40">eyJhbGci...</span>
          </div>

          <p className="mt-4 text-xs text-mute">
            Vite only reads .env when it starts, so stop the dev server and run{' '}
            <code className="font-mono">npm run dev</code> again after saving.
          </p>
        </div>
      </div>
    </div>
  )
}
