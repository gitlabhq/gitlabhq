import { ApolloLink, Observable, FetchResult, Operation, NextLink } from "@apollo/client/core"
import type { Consumer } from "@rails/actioncable"
import { print } from "graphql"

type RequestResult = FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>
type ConnectionParams = object | ((operation: Operation) => object)

class ActionCableLink extends ApolloLink {
  cable: Consumer
  channelName: string
  actionName: string
  connectionParams: ConnectionParams

  constructor(options: {
    cable: Consumer, channelName?: string, actionName?: string, connectionParams?: ConnectionParams
  }) {
    super()
    this.cable = options.cable
    this.channelName = options.channelName || "GraphqlChannel"
    this.actionName = options.actionName || "execute"
    this.connectionParams = options.connectionParams || {}
  }

  // Interestingly, this link does _not_ call through to `next` because
  // instead, it sends the request to ActionCable.
  request(operation: Operation, _next: NextLink): Observable<RequestResult> {
    return new Observable((observer) => {
      var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16)
      var actionName = this.actionName
      var connectionParams = (typeof this.connectionParams === "function") ?
        this.connectionParams(operation) : this.connectionParams
      var channel = this.cable.subscriptions.create(Object.assign({},{
        channel: this.channelName,
        channelId: channelId
      }, connectionParams), {
        connected: function() {
          this.perform(
            actionName,
            {
              query: operation.query ? print(operation.query) : null,
              variables: operation.variables,
              // This is added for persisted operation support:
              operationId: (operation as {operationId?: string}).operationId,
              operationName: operation.operationName
            }
          )
        },
        received: function(payload) {
          if (payload?.result?.data || payload?.result?.errors) {
            observer.next(payload.result)
          }

          if (!payload.more) {
            observer.complete()
          }
        }
      })
      // Make the ActionCable subscription behave like an Apollo subscription
      return Object.assign(channel, {closed: false})
    })
  }
}

export default ActionCableLink
