import AblyLink from "../AblyLink"
import { Realtime } from "ably"
import { Operation } from "@apollo/client/core"
import { parse } from "graphql"
function createAbly() {
  const _channels: {[key: string]: any } = {}
  const log: any[] = []

  const ably = {
    _channels: _channels,
    log: log,
    auth: {
      clientId: null,
    },
    channels: {
      get(channelName: string) {
        return _channels[channelName] ||= {
          _listeners: [] as [string, Function][],
          name: channelName,
          presence: {
            enterClient(_clientName: string, _status: string) {},
            leaveClient(_clientName: string) {},
          },
          detach(callback: Function) {
            callback()
          },
          subscribe(eventName: string, callback: Function) {
            log.push(["subscribe", channelName, eventName])
            this._listeners.push([eventName, callback])
          },
          unsubscribe(){
            log.push(["unsubscribe", channelName])
          }
        }
      },
      release(channelName: string) {
        delete _channels[channelName]
      }
    },
    __testTrigger(channelName: string, eventName: string, data: any) {
      const channel = this.channels.get(channelName)
      const handler = channel._listeners.find((l: any) => l[0] == eventName)
      if (handler) {
        handler[1](data)
      }
    }
  }

  return (ably as unknown) as Realtime
}

function createOperation(options: { subscriptionId: string | null }) {
  return ({
    query: parse("subscription { foo { bar } }"),
    variables: { a: 1 },
    operationId: "operationId",
    operationName: "operationName",
    getContext: () => {
      return {
        response: {
          headers: {
            get: (key: string) => {
              if (key == "X-Subscription-ID") {
                return options.subscriptionId
              } else {
                return null
              }
            }
          }
        }
      }
    }
  } as unknown) as Operation
}
describe("AblyLink", () => {
  test("delegates to Ably", () => {
    var mockAbly = createAbly()
    var log = (mockAbly as any).log
    var operation = createOperation({subscriptionId: "sub-1234"})

    var nextLink = (operation: any) => {
      log.push(["forward", operation.operationName])
      return {
        subscribe(info: any) {
          info.next()
        }
      } as any
    }

    var observable = new AblyLink({ ably: mockAbly}).request(operation, nextLink)

    observable.subscribe(function(result: any) {
      log.push(["received", result])
    });

    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: null }, more: true} });
    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: "data 1" }, more: true} });
    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: "data 2" }, more: false} });

    expect(log).toEqual([
      ["forward", "operationName"],
      ["subscribe", "sub-1234", "update"],
      ["received", { data: null }],
      ["received", { data: "data 1" }],
      ["received", { data: "data 2" }],
      ["unsubscribe", "sub-1234"]
    ])
  })

  test("it doesn't call ably when the subscription header isn't present", () => {
    var mockAbly = createAbly()
    var log = (mockAbly as any).log
    var operation = createOperation({subscriptionId: null})

    var nextLink = (operation: any) => {
      log.push(["forward", operation.operationName])
      return {
        subscribe(info: any) {
          info.next()
        }
      } as any
    }

    var observable = new AblyLink({ ably: mockAbly}).request(operation, nextLink)

    observable.subscribe(function(result: any) {
      log.push(["received", result])
    });

    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: null }, more: true} });
    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: "data 1" }, more: true} });
    (mockAbly as any).__testTrigger("sub-1234", "update", { data: { result: { data: "data 2" }, more: false} });

    expect(log).toEqual([["forward", "operationName"]])
  })
})
