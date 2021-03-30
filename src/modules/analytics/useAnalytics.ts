import { useRouter } from 'next/router'
import { useEffect } from 'react'

import { useMatomo } from '@/modules/analytics/useMatomo'

export interface AnalyticsService {
  init: () => void
  registerPageView: (url: string) => void
}

/**
 * Registers client side route transitions with an analytics service.
 */
export function useAnalytics(): void {
  const router = useRouter()
  const service = useMatomo()

  useEffect(() => {
    service.init()

    /**
     * `routeChangeComplete` does not run for the first page load unless the
     * query string is hydrated later on, so here we log a page view if this
     * is the first render and there's no query string.
     *
     * @see https://github.com/vercel/next.js/issues/11639
     */
    if (!router.asPath.includes('?')) {
      service.registerPageView(router.asPath)
    }
    /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [])

  useEffect(() => {
    router.events.on('routeChangeComplete', service.registerPageView)

    return () => {
      router.events.off('routeChangeComplete', service.registerPageView)
    }
  }, [router.events, service])
}
