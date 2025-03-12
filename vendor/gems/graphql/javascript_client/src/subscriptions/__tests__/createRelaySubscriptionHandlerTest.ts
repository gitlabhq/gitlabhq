import createRelaySubscriptionHandler from "../createRelaySubscriptionHandler"
import { createLegacyRelaySubscriptionHandler } from "../createRelaySubscriptionHandler"
import type { Consumer } from "@rails/actioncable"
import { Network } from 'relay-runtime'

describe("createRelaySubscriptionHandler", () => {
  it("returns a function producing a observable subscription", () => {
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => ({ unsubscribe: () => ( true) })
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Consumer
    }

    var handler = createRelaySubscriptionHandler(options)
    var fetchQuery: any
    // basically, make sure this doesn't blow up during type-checking or runtime
    expect(Network.create(fetchQuery, handler)).toBeTruthy()
  })

  it("doesn't send an empty string when no string is given", () => {
    var channel: any;
    var performLog: any[] = [];
    var dummyActionCableConsumer = {
      subscriptions: {
        create: (opts1: any, opts2: any) => {
          channel = Object.assign(
            opts1,
            opts2,
            {
              unsubscribe: () => true,
              perform: (event: string, payload: object) => performLog.push([event, payload]),

            }
          )
          return channel
        }
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Consumer
    }

    var handler = createRelaySubscriptionHandler(options)
    var observable = handler({id: "abc", text: null, name: "def", operationKind: "subscription", metadata: {}}, { abc: true});
    observable.subscribe({})
    channel.connected()
    var expectedLog = [
      [
        'execute',
        {
          variables: { abc: true },
          operationName: 'def',
          query: null,
          operationId: null
        }
      ]
    ]
    expect(performLog).toEqual(expectedLog)
  })
})

describe("createLegacyRelaySubscriptionHandler", () => {
  it("still works", () => {
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => ({ unsubscribe: () => ( true) })
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Consumer
    }

    expect(createLegacyRelaySubscriptionHandler(options)).toBeInstanceOf(Function)
  })
})
