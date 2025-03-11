// An Apollo Link for using graphql-pro's Pusher subscriptions
//
// @example Adding subscriptions to a HttpLink
//   // Load Pusher and create a client
//   import Pusher from "pusher-js"
//   var pusherClient = new Pusher("your-app-key", { cluster: "us2" })
//
//   // Build a combined link, initialize the client:
//   const pusherLink = new PusherLink({pusher: pusherClient})
//   const link = ApolloLink.from([authLink, pusherLink, httpLink])
//   const client = new ApolloClient(link: link, ...)
//
// @example Building a subscription, then subscribing to it
//  subscription = client.subscribe({
//    variables: { room: roomName},
//    query: gql`
//      subscription MessageAdded($room: String!) {
//        messageWasAdded(room: $room) {
//          room {
//            messages {
//              id
//              body
//              author {
//                screenname
//              }
//            }
//          }
//        }
//      }
//       `
//   })
//
//   subscription.subscribe({ next: ({data, errors}) => {
//     // Do something with `data` and/or `errors`
//   }})
//
import { ApolloLink, Observable, Observer, Operation, NextLink, FetchResult } from "@apollo/client/core"
import Pusher from "pusher-js"

type RequestResult = FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>

type Subscription = {
  closed: boolean;
  unsubscribe(): void;
}

class PusherLink extends ApolloLink {
  pusher: Pusher
  decompress: (result: string) => any

  constructor(options: { pusher: Pusher, decompress?: (result: string) => any}) {
    super()
    // Retain a handle to the Pusher client
    this.pusher = options.pusher
    if (options.decompress) {
      this.decompress = options.decompress
    } else {
      this.decompress = function(_result: string) {
        throw new Error("Received compressed_result but PusherLink wasn't configured with `decompress: (result: string) => any`. Add this configuration.")
      }
    }
  }

  request(operation: Operation, forward: NextLink): Observable<RequestResult> {
    const subscribeObservable = new Observable<RequestResult>((_observer: any) => {  })
    // Capture the super method
    const prevSubscribe = subscribeObservable.subscribe.bind(subscribeObservable)
    // Override subscribe to return an `unsubscribe` object, see
    // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L182-L212
    subscribeObservable.subscribe = (
        observerOrNext: Observer<RequestResult> | ((value: RequestResult) => void),
        onError?: (error: any) => void,
        onComplete?: () => void
      ): Subscription => {
      // Call super
      if (typeof(observerOrNext) == "function") {
        prevSubscribe(observerOrNext, onError, onComplete)
      } else {
        prevSubscribe(observerOrNext)
      }
      const observer = getObserver(observerOrNext, onError, onComplete)
      var subscriptionChannel: string
      // Check the result of the operation
      const resultObservable = forward(operation)
      // When the operation is done, try to get the subscription ID from the server
      resultObservable.subscribe({ next: (data: any) => {
        // If the operation has the subscription header, it's a subscription
        const response = operation.getContext().response
        // Check to see if the response has the header
        subscriptionChannel = response.headers.get("X-Subscription-ID")
        if (subscriptionChannel) {
          // Set up the pusher subscription for updates from the server
          const pusherChannel = this.pusher.subscribe(subscriptionChannel)
          // Pass along the initial payload:
          if (data.data && Object.keys(data.data).length > 0) {
            observer.next(data)
          }
          // Subscribe for more update
          pusherChannel.bind("update", (payload: any) => {
            this._onUpdate(subscriptionChannel, observer, payload)
          })
        } else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      },
      error: observer.error,
      // complete: observer.complete Don't pass this because Apollo unsubscribes if you do
      })

      // Return an object that will unsubscribe _if_ the query was a subscription.
      return {
        closed: false,
        unsubscribe: () => {
          subscriptionChannel && this.pusher.unsubscribe(subscriptionChannel)
        }
      }
    }
    return subscribeObservable
  }

  _onUpdate(subscriptionChannel: string, observer: { next: Function, complete: Function }, payload: {more: boolean, compressed_result?: string, result?: object}): void {
    let result: any
    if (payload.compressed_result) {
      result = this.decompress(payload.compressed_result)
    } else {
      result = payload.result
    }
    if (result) {
      // Send the new response to listeners
      observer.next(result)
    }
    if (!payload.more) {
      // This is the end, the server says to unsubscribe
      this.pusher.unsubscribe(subscriptionChannel)
      observer.complete()
    }
  }
}



// Turn `subscribe` arguments into an observer-like thing, see getObserver
// https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L347-L361
function getObserver<T>(
  observerOrNext: Function | Observer<T>,
  onError?: (e: Error) => void,
  onComplete?: () => void,
) {
  if (typeof observerOrNext === 'function') {
    // Duck-type an observer
    return {
      next: (v: T) => observerOrNext(v),
      error: (e: Error) => onError && onError(e),
      complete: () => onComplete && onComplete(),
    }
  } else {
    // Make an object that calls to the given object, with safety checks
    return {
      next: (v: T) => observerOrNext.next && observerOrNext.next(v),
      error: (e: Error) => observerOrNext.error && observerOrNext.error(e),
      complete: () => observerOrNext.complete && observerOrNext.complete(),
    }
  }
}

export default PusherLink
