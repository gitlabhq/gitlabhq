import type Pusher from "pusher-js"
import type { Channel } from "pusher-js"

type PusherFetcherOptions = {
  pusher: Pusher,
  url: String,
  fetch?: typeof fetch,
  fetchOptions: any,
}

type SubscriptionIteratorPayload = {
  value: any,
  done: Boolean
}

export default function createPusherFetcher(options: PusherFetcherOptions) {
  var currentChannel: Channel | null = null

  return async function*(graphqlParams: any, _fetcherParams: any) {
    var nextPromiseResolve: Function | null = null
    var shouldBreak = false

    var iterator = {
      [Symbol.asyncIterator]() {
        return {
          next(): Promise<SubscriptionIteratorPayload> {
            return new Promise((resolve, _reject) => {
              nextPromiseResolve = resolve
            })
          },
          return(): Promise<SubscriptionIteratorPayload> {
            if (currentChannel) {
              currentChannel.unsubscribe()
              currentChannel = null
            }
            return Promise.resolve({ value: null, done: true })
          }
        }
      }
    }

    const fetchFn = options.fetch || window.fetch
    fetchFn("/graphql", {
      method: "POST",
      body: JSON.stringify(graphqlParams),
      headers: {
        'content-type': 'application/json',
      },
      ...options.fetchOptions
    }).then((r) => {
      const subId = r.headers.get("X-Subscription-ID")
      if (subId) {
        currentChannel && currentChannel.unsubscribe()
        currentChannel = options.pusher.subscribe(subId)
        currentChannel.bind("update", (payload: any) => {
          if (nextPromiseResolve) {
            nextPromiseResolve({ value: payload.result, done: false })
          }
        })

        if (nextPromiseResolve) {
          nextPromiseResolve({ value: r.json(), done: false })
        }
      } else {
        shouldBreak = true
        if (nextPromiseResolve) {
          nextPromiseResolve({ value: r.json(), done: false})
        }
      }
    })

    for await (const payload of iterator) {
      yield payload
      if (shouldBreak) {
        break
      }
    }
  }
}
