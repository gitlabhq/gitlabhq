import SubscriptionExchange from "../SubscriptionExchange"
import Pusher from "pusher-js"
import Urql from "urql"
import {parse} from "graphql"
import { nextTick } from "process"
import { Consumer } from "@rails/actioncable"

type MockChannel = {
  bind: (action: string, handler: Function) => void,
}

describe("SubscriptionExchange with Pusher", () => {
  var channelName = "1234"
  var log: any[]
  var pusher: any
  var options: any
  var pusherExchange: any
  var operation: any

  beforeEach(() => {
    log = []
    pusher = {
      _channels: {},
      trigger: function(channel: string, event: string, data: any) {
        var handlers = this._channels[channel]
        if (handlers) {
          handlers.forEach(function(handler: [string, Function]) {
            if (handler[0] == event) {
              handler[1](data)
            }
          })
        }
      },
      subscribe: function(channel: string): MockChannel {
        log.push(["subscribe", channel])
        var handlers = this._channels[channel]
        if (!handlers) {
          handlers = this._channels[channel] = []
        }

        return {
          bind: (action: string, handler: Function): void => {
            handlers.push([action, handler])
          }
        }
      },
      unsubscribe: (channel: string): void => {
        delete pusher._channels[channel]
        log.push(["unsubscribe", channel])
      },
    }

    options = {
      pusher: (pusher as unknown) as Pusher
    }
    pusherExchange = SubscriptionExchange.create(options)

    operation = {
      query: parse("{ foo { bar } }"),
      variables: {},
      key: Number(channelName),
      context: {
        url: "/graphql",
        requestPolicy: "network-only",
        fetch: () => {
          var headers = new Headers
          headers.append("X-Subscription-ID", channelName)
          const jsonData = { data: { foo: "bar" }}
          return Promise.resolve(({
            headers: headers,
            json: () => { return jsonData }
          } as unknown) as Response)
        }
      },
      kind: "subscription",
    } as Urql.Operation
  })

  it("calls through to handlers and can be unsubscribed", () => {
    const subscriber = pusherExchange(operation)
    const next = (data: any) => { log.push(["next", data]) }
    const error = (err: any) => { log.push(["error", err]) }
    const complete = (data: any) => { log.push(["complete", data]) }
    const subscription = subscriber.subscribe({ next, error, complete })
    return new Promise((resolve, _reject) => {
      nextTick(() => {
        pusher.trigger(channelName, { result: {}, more: true })
        expect(Object.keys(pusher._channels)).toEqual([channelName])
        subscription.unsubscribe()
        expect(Object.keys(pusher._channels)).toEqual([])
        const expectedLog = [
          ["subscribe", "1234"],
          ["next", { data: { foo: "bar" } }],
          ["unsubscribe", "1234"]
        ]
        expect(log).toEqual(expectedLog)
        resolve(true)
      })
    })

  })
})

describe("SubscriptionExchange with ActionCable", () => {
  it("calls through to handlers", () => {
    var handlers: any
    var log: [string, any][]= []

    var dummyActionCableConsumer = {
      subscriptions: {
        create: (channelName: string, newHandlers: any) => {
          log.push(["create", channelName])
          handlers = newHandlers
          return {
            perform: (evt: string, data: any) => {
              log.push([evt, data])
            },
            unsubscribe: () => {
              log.push(["unsubscribed", null])
            }
          }
        }
      }
    }

    var options = {
      consumer: (dummyActionCableConsumer as unknown) as Consumer,
      channelName: "CustomChannel"
    }

    var exchange = SubscriptionExchange.create(options);
    var parsedQuery = parse("{ foo { bar } }")
    var operation = {
      query: parsedQuery,
      variables: {},
      context: {
        url: "/graphql",
        requestPolicy: "network-only",
      },
      kind: "subscription",
    } as Urql.Operation

    var subscriber = exchange(operation)
    const next = (data: any) => { log.push(["next", data]) }
    const error = (err: any) => { log.push(["error", err]) }
    const complete = (data: any) => { log.push(["complete", data]) }
    const subscription = subscriber.subscribe({ next, error, complete })


    return new Promise((resolve, _reject) => {
      nextTick(() => {
        handlers.connected() // trigger the GraphQL send
        handlers.received({ result: { data: { a: "1" } }, more: false })
        subscription.unsubscribe()
        const expectedLog = [
          ["create", "CustomChannel"],
          ["execute", { query: parsedQuery, variables: {} }],
          ["next", { data: { a: "1" } }],
          ["complete", undefined],
          ["unsubscribed", null],
        ]
        expect(log).toEqual(expectedLog)
        resolve(true)
      })
    })
  })
})
