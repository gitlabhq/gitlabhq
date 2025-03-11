import { Realtime, Types } from "ably"
// TODO:
// - end-to-end test
// - extract update code, inject it as a function?

interface AblyHandlerOptions {
  ably: Realtime
  fetchOperation: Function
}

interface GraphQLError {
  message: string
  path: (string | number)[]
  locations: number[][]
  extensions?: object
}

type OnErrorData = AblyError | Error| GraphQLError[]

interface ApolloObserver {
  onError: (err: OnErrorData) => void
  onNext: Function
  onCompleted: Function
}

const anonymousClientId = "graphql-subscriber"

// Current max. number of rewound messages in the initial response to
// subscribe. See
// https://github.com/ably/docs/blob/baa0a4666079abba3a3e19e82eb99ca8b8a735d0/content/realtime/channels/channel-parameters/rewind.textile#additional-information
// Note that using a higher value emits a warning.
const maxNumRewindMessages = 100

class AblyError extends Error {
  constructor(public reason: Types.ErrorInfo) {
    super(reason.message)
  }

  get code() {
    return this.reason.code
  }

  get statusCode() {
    return this.reason.statusCode
  }
}

function createAblyHandler(options: AblyHandlerOptions) {
  const { ably, fetchOperation } = options

  const isAnonymousClient = () =>
    !ably.auth.clientId || ably.auth.clientId === "*"

  return (
    operation: object,
    variables: object,
    cacheConfig: object,
    observer: ApolloObserver
  ) => {
    let channel: Types.RealtimeChannelCallbacks | null = null

    const dispatchResult = (result: { errors?: GraphQLError[]; data: any }) => {
      if (result) {
        if (result.errors) {
          // What kind of error stuff belongs here?
          observer.onError(result.errors)
        } else if (result.data && Object.keys(result.data).length > 0) {
          observer.onNext({ data: result.data })
        }
      }
    }

    const updateHandler = (message: Types.Message) => {
      // TODO Extract this code
      // When we get a response, send the update to `observer`
      const payload = message.data

      dispatchResult(payload.result)
      if (!payload.more) {
        // Subscription is finished
        observer.onCompleted()
      }
    }
    ;(async () => {
      try {
        // POST the subscription like a normal query
        const response = await fetchOperation(operation, variables, cacheConfig)

        const channelName = response.headers.get("X-Subscription-ID")
        if (!channelName) {
          throw new Error("Missing X-Subscription-ID header")
        }

        const channelKey = response.headers.get("X-Subscription-Key")

        channel = ably.channels.get(channelName, {
          params: { rewind: String(maxNumRewindMessages) },
          cipher: channelKey ? { key: channelKey } : undefined,
          modes: ["SUBSCRIBE", "PRESENCE"]
        })

        channel.on("failed", function(stateChange: Types.ChannelStateChange) {
          observer.onError(
            stateChange.reason
              ? new AblyError(stateChange.reason)
              : new Error("Ably channel changed to failed state")
          )
        })
        channel.on("suspended", function(
          stateChange: Types.ChannelStateChange
        ) {
          // Note: suspension can be a temporary condition and isn't necessarily
          // an error, however we handle the case where the channel gets
          // suspended before it is attached because that's the only way to
          // propagate error 90010 (see https://help.ably.io/error/90010)
          if (
            stateChange.previous === "attaching" &&
            stateChange.current === "suspended"
          ) {
            observer.onError(
              stateChange.reason
                ? new AblyError(stateChange.reason)
                : new Error("Ably channel suspended before being attached")
            )
          }
        })

        // Register presence, so that we can detect empty channels and clean them up server-side
        const enterCallback = (errorInfo: Types.ErrorInfo | null | undefined) => {
          if (errorInfo && channel) {
            observer.onError(new AblyError(errorInfo))
          }
        }
        if (isAnonymousClient()) {
          channel.presence.enterClient(
            anonymousClientId,
            "subscribed",
            enterCallback
          )
        } else {
          channel.presence.enter("subscribed", enterCallback)
        }

        // When you get an update from ably, give it to Relay
        channel.subscribe("update", updateHandler)

        // Dispatch the result _after_ setting up the channel,
        // because Relay might immediately dispose of the subscription.
        // (In that case, we want to make sure the channel is cleaned up properly.)
        dispatchResult(response.body)
      } catch (error) {
        observer.onError(error as Error)
      }
    })()

    return {
      dispose: async () => {
        try {
          if (channel) {
            const disposedChannel = channel
            channel = null
            disposedChannel.unsubscribe()

            // Ensure channel is no longer attaching, as otherwise detach does
            // nothing
            if (disposedChannel.state === "attaching") {
              await new Promise<void>((resolve, _reject) => {
                const onStateChange = (
                  stateChange: Types.ChannelStateChange
                ) => {
                  if (stateChange.current !== "attaching") {
                    disposedChannel.off(onStateChange)
                    resolve()
                  }
                }
                disposedChannel.on(onStateChange)
              })
            }

            await new Promise<void>((resolve, reject) => {
              disposedChannel.detach(err => {
                if (err) {
                  reject(new AblyError(err))
                } else {
                  resolve()
                }
              })
            })

            ably.channels.release(disposedChannel.name)
          }
        } catch (error) {
          observer.onError(error as Error)
        }
      }
    }
  }
}

export { createAblyHandler, AblyHandlerOptions, OnErrorData }
