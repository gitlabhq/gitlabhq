import ActionCableSubscriber from "./ActionCableSubscriber"
import PusherSubscriber from "./PusherSubscriber"
import Pusher from "pusher-js"
import type { Consumer } from "@rails/actioncable"

interface Subscriber {
  subscribe: Function
  unsubscribe: Function
}
/**
 * Modify an Apollo network interface to
 * subscribe an unsubscribe using `cable:`.
 * Based on `addGraphQLSubscriptions` from `subscriptions-transport-ws`.
 *
 * This function assigns `.subscribe` and `.unsubscribe` functions
 * to the provided networkInterface.
 * @example Adding ActionCable subscriptions to a HTTP network interface
 *   // Load ActionCable and create a consumer
 *   var ActionCable = require('@rails/actioncable')
 *   var cable = ActionCable.createConsumer()
 *   window.cable = cable
 *
 *   // Load ApolloClient and create a network interface
 *   var apollo = require('apollo-client')
 *   var RailsNetworkInterface = apollo.createNetworkInterface({
 *     uri: '/graphql',
 *     opts: {
 *       credentials: 'include',
 *     },
 *     headers: {
 *       'X-CSRF-Token': $("meta[name=csrf-token]").attr("content"),
 *     }
 *   });
 *
 *   // Add subscriptions to the network interface
 *   var addGraphQLSubscriptions = require("graphql-ruby-client/subscriptions/addGraphQLSubscriptions")
 *   addGraphQLSubscriptions(RailsNetworkInterface, {cable: cable})
 *
 *   // Optionally, add persisted query support:
 *   var OperationStoreClient = require("./OperationStoreClient")
 *   RailsNetworkInterface.use([OperationStoreClient.apolloMiddleware])
 *
 * @example Subscriptions with Pusher & graphql-pro
 *   var pusher = new Pusher(appId, options)
 *   addGraphQLSubscriptions(RailsNetworkInterface, {pusher: pusher})
 *
 * @param {Object} networkInterface - an HTTP NetworkInterface
 * @param {ActionCable.Consumer} options.cable - A cable for subscribing with
 * @param {Pusher} options.pusher - A pusher client for subscribing with
*/
function addGraphQLSubscriptions(networkInterface: any, options: { pusher?: Pusher, cable?: Consumer, subscriber?: Subscriber, decompress?: (compressed: string) => any, channelName?: string }) {
  if (!options) {
    options = {}
  }

  var subscriber: Subscriber
  if (options.subscriber) {
    // Right now this is just for testing
    subscriber = options.subscriber
  } else if (options.cable) {
    subscriber = new ActionCableSubscriber(options.cable, networkInterface, options.channelName)
  } else if (options.pusher) {
    subscriber = new PusherSubscriber(options.pusher, networkInterface, options.decompress)
  } else {
    throw new Error("Must provide cable: or pusher: option")
  }

  var networkInterfaceWithSubscriptions = Object.assign(networkInterface, {
    subscribe: function(request: any, handler: any) {
      var id = subscriber.subscribe(request, handler)
      return id
    },
    unsubscribe(id: number) {
      subscriber.unsubscribe(id)
    },
  })
  return networkInterfaceWithSubscriptions
}

export default addGraphQLSubscriptions
