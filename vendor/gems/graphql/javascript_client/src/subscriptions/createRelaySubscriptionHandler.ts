import { createActionCableHandler, ActionCableHandlerOptions } from "./createActionCableHandler"
import { createPusherHandler, PusherHandlerOptions } from "./createPusherHandler"
import { createAblyHandler, AblyHandlerOptions } from "./createAblyHandler"
import { RequestParameters, Variables, Observable } from "relay-runtime"

function createLegacyRelaySubscriptionHandler(options: ActionCableHandlerOptions | PusherHandlerOptions | AblyHandlerOptions) {
  var handler: any
  if ((options as ActionCableHandlerOptions).cable) {
    handler = createActionCableHandler(options as ActionCableHandlerOptions)
  } else if ((options as PusherHandlerOptions).pusher) {
    handler = createPusherHandler(options as PusherHandlerOptions)
  } else if ((options as AblyHandlerOptions).ably) {
    handler = createAblyHandler(options as AblyHandlerOptions)
  } else {
    throw new Error("Missing options for subscription handler")
  }
  return handler
}

/**
 * Transport-agnostic wrapper for Relay Modern subscription handlers.
 * @example Add ActionCable subscriptions
 *   var subscriptionHandler = createHandler({
 *     cable: cable,
 *     operations: OperationStoreClient,
 *   })
 *   var network = Network.create(fetchQuery, subscriptionHandler)
 * @param {ActionCable.Consumer} options.cable - A consumer from `.createConsumer`
 * @param {Pusher} options.pusher - A Pusher client
 * @param {Ably.Realtime} options.ably - An Ably client
 * @param {OperationStoreClient} options.operations - A generated `OperationStoreClient` for graphql-pro's OperationStore
 * @return {Function} A handler for a Relay Modern network
*/

function createRelaySubscriptionHandler(options: ActionCableHandlerOptions | PusherHandlerOptions | AblyHandlerOptions) {
  const handler = createLegacyRelaySubscriptionHandler(options)

  // Turn the handler into a relay-ready subscribe function
  return (request: RequestParameters, variables: Variables): any => {
    return Observable.from({
      subscribe: (observer: {
        next: any | ((v: any) => void);
        complete: () => void;
        error: (error: Error) => void;
      }) => {
        const client = handler(
          {
            text: request.text,
            name: request.name,
            id: request.id,
          },
          variables,
          {},
          {
            onError: (_error: Error) => {
              observer.error;
            },
            onNext: (res: any) => {
              if (!res || !res.data) {
                return;
              }
              observer.next(res);
            },
            onCompleted: observer.complete,
          }
        );

        return {
          unsubscribe: () => {
            client.dispose();
          },
        };
      },
    });
  };
}

export { createLegacyRelaySubscriptionHandler }
export default createRelaySubscriptionHandler
