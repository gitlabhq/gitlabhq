# graphql-ruby-client

# 1.14.5 (8 Nov 2024)

- `sync`: Fix `--dump-payload` with `--outfile` #5152

# 1.14.4 (8 Nov 2024)

- ActionCable: prevent unsubscribe being called twice with Relay and Urql #5150

# 1.14.3 (5 Nov 2024)

- `createActionCableHandler`: Make sure `unsubscribe` is only called once #5109

# 1.14.2 (4 Nov 2024)

- `sync`: Add a `--dump-payload` option for printing out the HTTP Post data #5143

# 1.14.1 (30 Sept 2024)

- `AblyLink`: don't set up an Ably subscription when no Subscription header is present #5113

# 1.14.0 (3 Jul 2024)

- Subscriptions: with Relay and ActionCable, don't send an empty query string (`""`) when using persisted operations #5008

# 1.13.3 (20 Mar 2024)

- Subscriptions: Support `urql` + ActionCable #4886

# 1.13.2 (28 Feb 2024)

- Update `glob` to v10+ to eliminate dependency on `inflight` #4859

# 1.13.1 (23 Feb 2024)

- createAblyHandler: add typing for `onError` handler #4845

# 1.13.0 (23 Jan 2024)

- Sync: add support for `generate-persisted-query-manifest` files #4798
- createActionCableHandler: remove needless `perform("send", ...)` call #4793

# 1.12.1 (29 Dec 2023)

- GraphiQL: support custom `channelName` and `url` in ActionCable fetcher #4756

# 1.12.0 (7 Dec 2023)

- Add GraphiQL support for subscriptions #4724

# 1.11.10 (17 Nov 2023)

- `createRelaySubscriptionHandler`: Support Relay persisted queries with ActionCable #4705

# 1.11.9 (1 Sept 2023)

- `createRelaySubscriptionHandler`: fix error handling in handler functions #4603

# 1.11.8 (9 May 2023)

- ActionCable: accept a custom `channelName` for `createActionCableHandler` and `addGraphQLSubscriptions` #4463

# 1.11.7 (24 February 2023)

- ActionCableLink: fix race condition #4359

# 1.11.6 (14 February 2023)

- Sync: fix `--changeset-version` #4328
- Improve verbose logging #4328

# 1.11.5 (27 January 2023)

- Sync: add a `--changeset-version` for use with Changesets #4304
- Sync: fix handling of `--header` with a single header

# 1.11.4 (4 January 2023)

- PusherLink: pass initial response along to the client #4282

# 1.11.3 (13 October 2022)

- `createAblySubscriptions`: don't use `Error.captureStackTrace` which isn't supported in all JS runtimes #4223
- `createAblySubscriptions`: properly handle empty initial response from the interpreter (`{}`) #4226

# 1.11.2 (26 August 2022)

- Sync: Add a `--header` option for custom headers #4171

# 1.11.1 (19 July 2022)

- Subscriptions: ActionCableLink: only forward the result if `data` or `errors` is present #4114

# 1.11.0 (4 July 2022)

- Subscriptions: Add `urql` support for Pusher #4129

# 1.10.7 (29 Mar 2022)

- Dependencies: loosen apollo client and graphql version requirements to accept newer versions #4008

# 1.10.6 (10 Jan 2022)

- Pusher Link: Don't pass along the `complete` handler because Apollo unsubscribes if you do #3830

# 1.10.5 (17 Dec 2021)

- Dependencies: replace `actioncable` with `@rails/actioncable` #3773

# 1.10.4 (19 Nov 2021)

- Sync: Also make sure documents are valid after removing `@client` fields #3715

# 1.10.3 (18 Nov 2021)

- Sync: Remove any fields with `@client` before sending operations to the server #3712

# 1.10.2 (25 Oct 2021)

- Pusher Link: Properly forward network errors to subscribers #3638

# 1.10.1 (22 Sept 2021)

- Sync: Add `--apollo-codegen-json-output=...` option #3616

# 1.10.0 (25 Aug 2021)

- Remove direct dependency on `request` #3594
- Update `createRelaySubscriptionHandler` to support Relay 11. Use `createLegacyRelaySubscriptionHandler` to get the old behavior. #3594

# 1.9.3 (31 Mar 2021)

- Move `graphql` and `@apollo/client` to `peerDeps` for more flexible versions #3395

# 1.9.2 (19 Feb 2021)

- Remove dependency on React by changing imports to `@apollo/client/core` #3349

# 1.9.1 (11 Feb 2021)

- Support graphql 15.x in dependencies #3334

## 1.9.0 (10 Feb 2021)

- Move "compiled" `.js` files into the root directory of the published NPM package (instead of `dist/`). To upgrade, remove `dist/` from your import paths. (These files will be treated as public APIs in their own right, exposed independently to support smaller bundle sizes.) #2768
- Upgrade dependency from `apollo-link` to `@apollo/client` #3270

## 1.8.2 (2 Feb 2021)

- Pusher: Accept a `decompress:` function for handling compressed payloads #3311

## 1.8.1 (16 Nov 2020)

- Sync: When `--url` is omitted, generate an outfile without syncing with a server

## 1.8.0 (10 Nov 2020)

- Ably: Support server-side `cipher_base:` config in the client

## 1.7.12 (3 Nov 2020)

- Ably: Add `rewind:` config so messages aren't lost between subscribe and registration of listener. #3210
- Ably: Fix race condition where error was raised before the channel was available. #3210

## 1.7.11 (15 June 2020)

- Ably: Improve channel state handling in case the initial subscription result contains errors #2993

## 1.7.10 (13 June 2020)

- Ably: Improve error handling and channel cleanup #2991

## 1.7.9 (15 May 2020)

- Ably: _completely_ unsubscribe when subscriptions are done #2944
- Ably: propagate errors from subscriptions #2944

## 1.7.8 (1 May 2020)

- `sync`: Add support for Apollo-Android's `OperationOutput.json` #2914

## 1.7.7 (15 Apr 2020)

- Ably handler: dispatch initial response #2866
- Ably handler: catch any error in initial HTTP call #2877

## 1.7.6 (3 Apr 2020)

- Fix ActionCableLink sending unsubcribe to ActionCable #2842

## 1.7.5 (4 Mar 2020)

- Add missing dependency declarations

## 1.7.4 (18 Feb 2020)

- Move all exports to top level
- Fix sync body handling: wait for all chunks, improve verbose output

## 1.7.3 (17 Feb 2020)

- Fix CLI for TypeScript

## 1.7.2 (17 Feb 2020)

- Convert outfile generators to TypeScript and include them in published package

## 1.7.1 (17 Feb 2020)

- Fix `bin` configuration in package.json

## 1.7.0 (17 Feb 2020)

- Rewrite in TypeScript

## 1.6.8 (18 Sept 2019)

- Properly send `Content-Type: application/json` when posting persisted operations

## 1.6.7 (18 Sept 2019)

- Add post data to `--verbose` output of `sync`

## 1.6.6 (6 Aug 2019)

- Add `--relay-persisted-output` for working with Relay Compiler's new `--persist-output` option #2415

## 1.6.5 (17 July 2019)

- Update dependencies #2335

## 1.6.4 (11 May 2019)

- Add `--verbose` option to `sync` #2075
- Support Relay 2.0.0 #2121
- ActionCableLink: support subscriber when there are errors but no data #2176

## 1.6.3 (11 Jan 2019)

- Fix `.unsubscribe()` for PusherLink #2042

## 1.6.2 (14 Dec 2018)

- Support identified Ably client #2003

## 1.6.1 (30 Nov 2018)

- Support `ably:` option for Relay subscriptions

## 1.6.0 (19 Nov 2018)

- Fix unused requires #1943
- Add `generateClient` function to generate code _without_ the HTTP call #1941

## 1.5.0 (27 October 2018)

- Fix `export` usage in PusherLink, use `require` and `module.exports` instead #1889
- Add `AblyLink` #1925

## 1.4.1 (19 Sept 2018)

- Add `connectionOptions` to ActionCableLink #1857

## 1.4.0 (12 Apr 2018)

- Add `PusherLink` for Apollo 2 Subscriptions on Pusher
- Add `OperationStoreLink` for Apollo 2 persisted queries

## 1.3.0 (30 Nov 2017)

- Support HTTPS, basic auth, query string and port in `sync` #1053
- Add Apollo 2 support for ActionCable subscriptions #1120
- Add `--outfile-type=json` for stored operation manifest #1142

## 1.2.0 (15 Nov 2017)

- Support Apollo batching middleware #1092

## 1.1.3 (11 Oct 2017)

- Fix Apollo + ActionCable unsubscribe function #1019

## 1.1.2 (9 Oct 2017)

- Add channel IDs to ActionCable subscriptions #1004

## 1.1.1 (21 Sept 2017)

- Add `--add-typename` option to `sync` #967

## 1.1.0 (18 Sept 2017)

- Add subscription clients for Apollo and Relay Modern

## 1.0.2 (22 Aug 2017)

- Remove debug output

## 1.0.1 (21 Aug 2017)

- Rename from `graphql-pro-js` to `graphql-ruby-client`

## 1.0.0 (31 Jul 2017)

- Add `sync` task
