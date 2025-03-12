import PusherLink from "../PusherLink"
import { parse } from "graphql"
import Pusher from "pusher-js"
import { Operation } from "@apollo/client/core"
import pako from 'pako'

type MockChannel = {
  bind: (action: string, handler: Function) => void,
}

describe("PusherLink", () => {
  var channelName = "abcd-efgh"
  var log: any[]
  var pusher: any
  var options: any
  var link: any
  var query: any
  var operation: Operation

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
        log.push(["unsubscribe", channel])
      },
    }

    options = {
      pusher: (pusher as unknown) as Pusher
    }
    link = new PusherLink(options)

    query = parse("subscription { foo { bar } }")

    operation = ({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName",
      getContext: () => {
        return {
          response: {
            headers: {
              get: (headerName: string) => {
                if (headerName == "X-Subscription-ID") {
                  return channelName
                } else {
                  throw "Unsupported header name: " + headerName
                }
              }
            }
          }
        }
      }
    } as unknown) as Operation
  })

  it("forwards errors to error handlers", () => {
    let passedErrorHandler: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function, error: Function, complete: Function }): void => {
          passedErrorHandler = options.error
          {}
        }
      }
    })

    let errorHandlerWasCalled = false
    function createdErrorHandler(_err: Error) {
      errorHandlerWasCalled = true
    }

    observable.subscribe(function(result: any) {
      log.push(["received", result])
    }, createdErrorHandler)

    if (passedErrorHandler) {
      passedErrorHandler(new Error)
    }

    expect(errorHandlerWasCalled).toBe(true)
  })

  it("doesn't call the link request's `complete` handler because otherwise Apollo would clean up subscriptions", () => {
    let passedComplete: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function, error: Function, complete: Function }): void => {
          passedComplete = options.complete
          {}
        }
      }
    })

    observable.subscribe(function(result: any) {
      log.push(["received", result])
    }, null, function() { log.push(["completed"])})

    expect(log).toEqual([])
    expect(passedComplete).toBeUndefined()
  })

  it("delegates to pusher", () => {
    var requestFinished: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function }): void => {
          requestFinished = options.next
        }
      }
    })

    // unpack the underlying subscription
    observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

    // Pretend the HTTP link finished
    requestFinished({ data: "initial payload" })

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 1"
      },
      more: true
    })

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 2"
      },
      more: false
    })

    expect(log).toEqual([
      ["subscribe", "abcd-efgh"],
      ["received", { data: "initial payload"}],
      ["received", { data: "data 1" }],
      ["received", { data: "data 2" }],
      ["unsubscribe", "abcd-efgh"]
    ])
  })

  it("delegates a manual unsubscribe to pusher", () => {
    var requestFinished: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function }): void => {
          requestFinished = options.next
        }
      }
    })

    // unpack the underlying subscription
    var subscription = observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

    // Pretend the HTTP link finished
    requestFinished({ data: "initial payload" })

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.unsubscribe()

    expect(log).toEqual([
      ["subscribe", "abcd-efgh"],
      ["received", { data: "initial payload"}],
      ["received", { data: "data 1" }],
      ["unsubscribe", "abcd-efgh"]
    ])
  })

  it("doesn't send empty initial responses", () => {
    var requestFinished: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function }): void => {
          requestFinished = options.next
        }
      }
    })

    // unpack the underlying subscription
    var subscription = observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

    // Pretend the HTTP link finished
    requestFinished({ data: null })

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.unsubscribe()

    expect(log).toEqual([
      ["subscribe", "abcd-efgh"],
      ["received", { data: "data 1" }],
      ["unsubscribe", "abcd-efgh"]
    ])
  })


  it("throws an error when no `decompress:` is configured", () => {
    const link = new PusherLink({
      pusher: new Pusher("123"),
    })

    const observer = {
      next: (_result: object) => {},
      complete: () => {},
    }

    const payload = {
      more: true,
      compressed_result: "abcdef",
    }

    expect(() => {
      link._onUpdate("abc", observer, payload)
    }).toThrow("Received compressed_result but PusherLink wasn't configured with `decompress: (result: string) => any`. Add this configuration.")
  })

  it("decompresses compressed_result", () => {
    const link = new PusherLink({
      pusher: new Pusher("123"),
      decompress: (compressed) => {
        const buff = Buffer.from(compressed, 'base64');
        return JSON.parse(pako.inflate(buff, { to: 'string' }));
       },
    })

    const results: Array<object | string> = []

    const observer = {
      next: (result: object) => { results.push(result) },
      complete: () => { results.push("complete") },
    }

    const compressedData = pako.deflate(JSON.stringify({ a: 1, b: 2}))
    // Browsers have `TextEncoder` for this
    const compressedStr = Buffer.from(compressedData).toString("base64")
    const payload = {
      more: true,
      compressed_result: compressedStr,
    }

    // Send a dummy payload and then terminate the subscription
    link._onUpdate("abc", observer, payload)
    link._onUpdate("abc", observer, { more: false })
    expect(results).toEqual([{a: 1, b: 2}, "complete"])
  })
})
