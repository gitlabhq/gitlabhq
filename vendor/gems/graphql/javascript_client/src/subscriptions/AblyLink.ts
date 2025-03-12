// An Apollo Link for using graphql-pro's Ably subscriptions
//
// @example Adding subscriptions to a HttpLink
//   // Load Ably and create a client
//   var Ably = require('ably')
//   // Be sure to create an API key with "Subscribe" and "Presence" permissions only,
//   // and use that limited API key here:
//   var ablyClient = new Ably.Realtime({ key: "yourapp.key:secret" })
//
//   // Build a combined link, initialize the client:
//   const ablyLink = new AblyLink({ably: ablyClient})
//   const link = ApolloLink.from([authLink, ablyLink, httpLink])
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
import { ApolloLink, Observable, FetchResult, NextLink, Operation } from "@apollo/client/core"
import { Realtime } from "ably"

type RequestResult = Observable<FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>>

class AblyLink extends ApolloLink {
  ably: Realtime

  constructor(options: { ably: Realtime }) {
    super()
    // Retain a handle to the Ably client
    this.ably = options.ably
  }

  request(operation: Operation, forward: NextLink): RequestResult {
    return new Observable((observer) => {
      // Check the result of the operation
      forward(operation).subscribe({ next: (data) => {
        // If the operation has the subscription header, it's a subscription
        const subscriptionChannelConfig = this._getSubscriptionChannel(operation)
        if (subscriptionChannelConfig.channel) {
          // This will keep pushing to `.next`
          this._createSubscription(subscriptionChannelConfig, observer)
        }
        else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      }})
    })
  }

  _getSubscriptionChannel(operation: Operation) {
    const response = operation.getContext().response
    // Check to see if the response has the header
    const subscriptionChannel = response.headers.get("X-Subscription-ID")
    // The server returns this header when encryption is enabled.
    const cipherKey = response.headers.get("X-Subscription-Key")
    return { channel: subscriptionChannel, key: cipherKey }
  }

  _createSubscription(subscriptionChannelConfig: { channel: string, key: string }, observer: { next: Function, complete: Function}) {
    const subscriptionChannel = subscriptionChannelConfig["channel"]
    const subscriptionKey = subscriptionChannelConfig["key"]
    const ablyOptions = subscriptionKey ? { cipher: { key: subscriptionKey } } : {}
    const ablyChannel = this.ably.channels.get(subscriptionChannel, ablyOptions)
    const ablyClientId = this.ably.auth.clientId
    // Register presence, so that we can detect empty channels and clean them up server-side
    if (ablyClientId) {
      ablyChannel.presence.enter()
    } else {
      ablyChannel.presence.enterClient("graphql-subscriber", "subscribed")
    }
    // Subscribe for more update
    ablyChannel.subscribe("update", function(message) {
      var payload = message.data
      const result = payload.result
      if (result) {
        // Send the new response to listeners
        observer.next(result)
      }
      if (!payload.more) {
        // This is the end, the server says to unsubscribe
        if (ablyClientId) {
          ablyChannel.presence.leave()
        } else {
          ablyChannel.presence.leaveClient("graphql-subscriber")
        }
        ablyChannel.unsubscribe()
        observer.complete()
      }
    })
  }
}

export default AblyLink
