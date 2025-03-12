import createActionCableFetcher from "../createActionCableFetcher"
import type { Consumer } from "@rails/actioncable"
import { parse } from "graphql"

describe("createActionCableFetcherTest", () => {
  it("yields updates for subscriptions", () => {
    var handlers: any
    var log: [string, any][]= []

    var dummyActionCableConsumer = {
      subscriptions: {
        create: (_conn: any, newHandlers: any) => {
          handlers = newHandlers
          return {
            perform: (evt: string, data: any) => {
              log.push([evt, data])
            }
          }
        }
      }
    }

    const fetchLog: any[] = []
    const dummyFetch = function(url: string, fetchArgs: any) {
      fetchLog.push([url, fetchArgs.custom])
      return Promise.resolve({ json: () => { {} } })
    }

    var options = {
      consumer: (dummyActionCableConsumer as unknown) as Consumer,
      url: "/some_graphql_endpoint",
      fetch: dummyFetch as typeof fetch,
      fetchOptions: {
        custom: true,
      }
    }

    var fetcher = createActionCableFetcher(options)


    const queryStr = "subscription listen { update { message } }"
    const doc = parse(queryStr)

    const res = fetcher({ operationName: "listen", query: queryStr, variables: {}}, { documentAST: doc })
    const promise = res.next().then((result) => {

      handlers.connected() // trigger the GraphQL send

      expect(result).toEqual({ value: { data: "hello" } , done: false })
      expect(fetchLog).toEqual([])
      expect(log).toEqual([
        ["execute", { operationName: "listen", query: queryStr, variables: {} }],
      ])
    })

    handlers.received({ result: { data: "hello" } }) // simulate an update

    return promise.then(() => {
      let res2 = fetcher({ operationName: null, query: "{ __typename } ", variables: {}}, {})
      const promise2 = res2.next().then(() => {
        expect(fetchLog).toEqual([["/some_graphql_endpoint", true]])
      })
      return promise2
    })
  })
})
