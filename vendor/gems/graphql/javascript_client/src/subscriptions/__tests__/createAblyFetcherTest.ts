import createAblyFetcher from "../createAblyFetcher"
import { Realtime } from "ably"

function createAbly() {
  const _channels: {[key: string]: any } = {}

  const ably = {
    _channels: _channels,
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
            this._listeners.push([eventName, callback])
          },
          unsubscribe(){}
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

  return ably
}


describe("createAblyFetcher", () => {
  it("yields updates for subscriptions", () => {
    const ably = createAbly()

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

    const fetcher = createAblyFetcher({
      ably: (ably as unknown) as Realtime,
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

      ably.__testTrigger("abcd", "update", { data: { result: { data: { hi: "Bonjour" } } } })

      return promise.then(() => {
        // Test non-subscriptions too:
        expect(Object.keys(ably._channels)).toEqual(["abcd"])
        const queryResult = fetcher({ variables: {}, operationName: null, body: "{ __typename }"}, {})
        return queryResult.next().then((res) => {
          expect(res.value.data).toEqual({ hi: "First response"})
          return queryResult.next().then((res2) => {
            expect(res2.done).toEqual(true)
            expect(ably._channels).toEqual({})
          })
        })
      })
    })
  })
})
