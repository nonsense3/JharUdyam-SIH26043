import { useState } from 'react'
import { IconImage } from './Icons'

/**
 * The citizen's photograph. Falls back to a labelled panel when there is no
 * image or the file cannot be loaded, so a broken link never breaks a layout.
 */
export default function ProblemImage({ src, alt, className = '', ratio = 'aspect-[4/3]' }) {
  const [failed, setFailed] = useState(false)
  const usable = Boolean(src) && !failed

  return (
    <div
      className={`relative overflow-hidden rounded-md border border-line bg-paper ${ratio} ${className}`}
    >
      {usable ? (
        <img
          src={src}
          alt={alt || 'Photograph submitted with this report'}
          loading="lazy"
          onError={() => setFailed(true)}
          className="h-full w-full object-cover"
        />
      ) : (
        <div className="flex h-full w-full flex-col items-center justify-center gap-2 text-mute">
          <IconImage width={22} height={22} />
          <p className="font-mono text-2xs uppercase tracking-[0.12em]">
            {src ? 'Photo unavailable' : 'No photo attached'}
          </p>
        </div>
      )}
    </div>
  )
}
