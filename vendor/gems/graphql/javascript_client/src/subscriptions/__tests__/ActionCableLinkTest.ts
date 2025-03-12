import ActionCableLink from "../ActionCableLink"
import { parse } from "graphql"
import type { Consumer } from "@rails/actioncable"
import { Operation } from "@apollo/client/core"

describe("ActionCableLink", () => {
  var log: any[]
  var cable: any
  var options: any
  var query: any
  var operation: Operation

  beforeEach(() => {
    log = []
    cable = {
      subscriptions: {
        create: function(channelName: string | object, options: {connected: Function, received: Function}) {
          var channel = channelName
          var params = typeof channel === "object" ? channel : { channel }
          var alreadyConnected = false
          var subscription = Object.assign(
            Object.create({
              perform: function(actionName: string, options: object) {
                log.push(["perform", { actionName: actionName, options: options }])
              },
              unsubscribe: function() {
                log.push(["unsubscribe"])
              }
            }),
            { params },
            options
          )

          subscription.connected = subscription.connected.bind(subscription)
          var received = subscription.received
          subscription.received = function(data: any) {
            if (!alreadyConnected) {
              alreadyConnected = true
              subscription.connected()
            }
            received(data)
          }
          subscription.__proto__.unsubscribe = subscription.__proto__.unsubscribe.bind(subscription)
          return subscription
        }
      }
    }
    options = {
      cable: (cable as unknown) as Consumer
    }

    query = parse("subscription { foo { bar } }")

    operation = ({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName"
    } as unknown) as Operation
  })

  it("delegates to the cable", () => {
    var observable = new ActionCableLink(options).request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(function(result: any) {
      log.push(["received", result])
    }) as any)._cleanup

    subscription.received({
      result: {
        data: null
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 2"
      },
      more: false
    })

    expect(log).toEqual([
      [
        "perform", {
          actionName: "execute",
          options: {
            query: "subscription {\n  foo {\n    bar\n  }\n}",
            variables: { a: 1 },
            operationId: "operationId",
            operationName: "operationName"
          }
        }
      ],
      ["received", { data: "data 1" }],
      ["received", { data: "data 2" }],
      ["unsubscribe"]
    ])
  })

  it("delegates a manual unsubscribe to the cable", () => {
    var observable = new ActionCableLink(options).request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(function(result: any) {
      log.push(["received", result])
    }) as any)._cleanup

    subscription.received({
      result: {
        data: null
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.unsubscribe()

    expect(log).toEqual([
      [
        "perform", {
          actionName: "execute",
          options: {
            query: "subscription {\n  foo {\n    bar\n  }\n}",
            variables: { a: 1 },
            operationId: "operationId",
            operationName: "operationName"
          }
        }
      ],
      ["received", { data: "data 1" }],
      ["unsubscribe"]
    ])
  })

  it("forward object connectionParams to subscription creation", () => {
    var observable = new ActionCableLink(Object.assign(options, { connectionParams: { test: 1 } })).
      request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(() => null) as any)._cleanup

    subscription.unsubscribe()

    expect(subscription.params["test"]).toEqual(1)
  })

  it("calls connectionParams during subscription creation to fetch additional params", () => {
    var observable = new ActionCableLink(
      Object.assign(options, { connectionParams: () => ({ test: 1 })} )
    ).request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(() => null) as any)._cleanup

    subscription.unsubscribe()

    expect(subscription.params["test"]).toEqual(1)
  })
})
