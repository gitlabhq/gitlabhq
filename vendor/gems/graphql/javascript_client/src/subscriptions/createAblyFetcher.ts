import type Types from "ably"

type AblyFetcherOptions = {
  ably: Types.Realtime,
  url: String,
  fetch?: typeof fetch,
  fetchOptions?: any,
}

type SubscriptionIteratorPayload = {
  value: any,
  done: Boolean
}

const clientName = "graphiql-subscriber"

export default function createAblyFetcher(options: AblyFetcherOptions) {
  var currentChannel: Types.Types.RealtimeChannelCallbacks | null = null

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
              currentChannel.presence.leaveClient(clientName)
              currentChannel.unsubscribe()
              const channelName = currentChannel.name
              currentChannel.detach(() => {
                options.ably.channels.release(channelName)
              })
              currentChannel = null
              nextPromiseResolve = null
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
      ... options.fetchOptions
    }).then((r) => {
      const subId = r.headers.get("X-Subscription-ID")
      if (subId) {
        currentChannel && currentChannel.unsubscribe()
        currentChannel = options.ably.channels.get(subId, { modes: ["SUBSCRIBE", "PRESENCE"] })
        currentChannel.presence.enterClient(clientName, "subscribed", (err) => {
          if (err) {
            console.error(err)
          }
        })
        currentChannel.subscribe("update", (message: Types.Types.Message) => {
          console.log("update", message)
          if (nextPromiseResolve) {
            nextPromiseResolve({ value: message.data.result, done: false })
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
