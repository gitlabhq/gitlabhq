import registry from "../registry"

describe("subscription registry", () => {
  it("adds and unsubscribes", () => {
    // A subscription is something that responds to `.unsubscribe`
    var wasUnsubscribed1 = false
    var subscription1 = {
      unsubscribe: function() {
        wasUnsubscribed1 = true
      }
    }
    var wasUnsubscribed2 = false
    var subscription2 = {
      unsubscribe: function() {
        wasUnsubscribed2 = true
      }
    }
    // Adding a subscription returns an ID for unsubscribing
    var id1 = registry.add(subscription1)
    var id2 = registry.add(subscription2)
    expect(typeof id1).toEqual("number")
    expect(typeof id2).toEqual("number")
    // Unsubscribing calls the `.unsubscribe `function
    registry.unsubscribe(id1)
    expect(wasUnsubscribed1).toEqual(true)
    expect(wasUnsubscribed2).toEqual(false)
    registry.unsubscribe(id2)
    expect(wasUnsubscribed1).toEqual(true)
    expect(wasUnsubscribed2).toEqual(true)
  })

  it("raises on unknown ids", () => {
    expect(() => {
      registry.unsubscribe(999)
    }).toThrow("No subscription found for id: 999")
  })
})
