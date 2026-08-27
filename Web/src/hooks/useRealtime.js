import { useEffect } from 'react'
import { supabase } from '../lib/supabase'

/**
 * Reloads a page when a table changes, so a release made in the government
 * portal appears on the collaboration board without anyone hitting refresh.
 */
export function useTableChanges(table, onChange, channelName) {
  useEffect(() => {
    const channel = supabase
      .channel(channelName ?? `watch-${table}`)
      .on('postgres_changes', { event: '*', schema: 'public', table }, () => onChange())
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [table, channelName])
}
