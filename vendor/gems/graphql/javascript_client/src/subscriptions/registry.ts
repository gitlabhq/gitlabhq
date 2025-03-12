interface ApolloSubscription {
  unsubscribe: Function
}

// State management for subscriptions.
// Used to add subscriptions to an Apollo network interface.
class ApolloSubscriptionRegistry {
  // Apollo expects unique ids to reference each subscription,
  // here's a simple incrementing ID generator which starts at 1
  // (so it's always truthy)
  _id: number

  // for unsubscribing when Apollo asks us to
  _subscriptions: {[key: number]: ApolloSubscription}

  constructor() {
    this._id = 1
    this._subscriptions = {}
  }

  add(subscription: ApolloSubscription): number {
    var id = this._id++
    this._subscriptions[id] = subscription
    return id
  }

  unsubscribe(id: number): void {
    var subscription = this._subscriptions[id]
    if (!subscription) {
      throw new Error("No subscription found for id: " + id)
    }
    subscription.unsubscribe()
    delete this._subscriptions[id]
  }
}

export default new ApolloSubscriptionRegistry

