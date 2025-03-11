import createPusherFetcher from "../createPusherFetcher"
import type Pusher from "pusher-js"

type MockChannel = {
  bind: (action: string, handler: Function) => void,
  unsubscribe: () => void,
}

describe("createPusherFetcher", () => {
  it("yields updates for subscriptions", () => {
    const pusher = {
      _channels: {} as {[key: string]: [string, Function][]},

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
        var handlers = this._channels[channel]
        if (!handlers) {
          handlers = this._channels[channel] = []
        }

        return {
          bind: (action: string, handler: Function): void => {
            handlers.push([action, handler])
          },
          unsubscribe: () => {
            delete this._channels[channel]
          }
        }
      },
      unsubscribe: (_channel: string): void => {
      },
    }

    const fetchLog: any[] = []
    const dummyFetch = function(url: string, fetchArgs: any) {
      fetchLog.push([url, fetchArgs.customOpt])
      const dummyResponse = {
        json: () => {
          return {
            data: {
              hi: "First response"
            }
          }
        },
        headers: {
          get() {
            return fetchArgs.body.includes("subscription") ? "abcd" : null
          }
        }
      }
      return Promise.resolve(dummyResponse)
    }

    const fetcher = createPusherFetcher({
      pusher: (pusher as unknown) as Pusher,
      url: "/graphql",
      fetch: ((dummyFetch as unknown) as typeof fetch),
      fetchOptions: {customOpt: true}
    })

    const result = fetcher({
      variables: {},
      operationName: "hello",
      body: "subscription hello { hi }"
    }, {})

    return result.next().then((res) => {
      expect(res.value.data.hi).toEqual("First response")
      expect(fetchLog).toEqual([["/graphql", true]])
    }).then(() => {
      const promise = result.next().then((res2) => {
        expect(res2).toEqual({ value: { data: { hi: "Bonjour" } }, done: false })
      })
      pusher.trigger("abcd", "update", { result: { data: { hi: "Bonjour" } } })

      return promise.then(() => {
        // Test non-subscriptions too:
        expect(Object.keys(pusher._channels)).toEqual(["abcd"])
        const queryResult = fetcher({ variables: {}, operationName: null, body: "{ __typename }"}, {})
        return queryResult.next().then((res) => {
          expect(res.value.data).toEqual({ hi: "First response"})
          return queryResult.next().then((res2) => {
            expect(res2.done).toEqual(true)
            expect(pusher._channels).toEqual({})
          })
        })
      })
    })
  })
})
