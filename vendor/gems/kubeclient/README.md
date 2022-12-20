# Kubeclient

[![Gem Version](https://badge.fury.io/rb/kubeclient.svg)](http://badge.fury.io/rb/kubeclient)
[![Build Status](https://travis-ci.org/abonas/kubeclient.svg?branch=master)](https://travis-ci.org/abonas/kubeclient)
[![Code Climate](http://img.shields.io/codeclimate/github/abonas/kubeclient.svg)](https://codeclimate.com/github/abonas/kubeclient)

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on all the entities available in kubernetes in both the core and group apis.
The client currently supports Kubernetes REST api version v1.
To learn more about groups and versions in kubernetes refer to [k8s docs](https://kubernetes.io/docs/api/)

## VULNERABILITY❗

If you use `Kubeclient::Config`, all gem versions released before 2022 could return incorrect `ssl_options[:verify_ssl]`,
endangering your connection and cluster credentials.
See [latest CHANGELOG.md](https://github.com/ManageIQ/kubeclient/blob/master/CHANGELOG.md) for details and which versions got a fix.
Open an issue if you want a backport to another version.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kubeclient'
```

And then execute:

```Bash
bundle
```

Or install it yourself as:

```Bash
gem install kubeclient
```

## Usage

Initialize the client:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api/', "v1")
```

Or without specifying version (it will be set by default to "v1")

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api/')
```

For A Group Api:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/apis/batch', 'v1')
```

Another option is to initialize the client with URI object:

```ruby
uri = URI::HTTP.build(host: "somehostname", port: 8080)
client = Kubeclient::Client.new(uri)
```

### SSL

It is also possible to use https and configure ssl with:

```ruby
ssl_options = {
  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),
  client_key:  OpenSSL::PKey::RSA.new(File.read('/path/to/client.key')),
  ca_file:     '/path/to/ca.crt',
  verify_ssl:  OpenSSL::SSL::VERIFY_PEER
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', "v1", ssl_options: ssl_options
)
```

As an alternative to the `ca_file` it's possible to use the `cert_store`:

```ruby
cert_store = OpenSSL::X509::Store.new
cert_store.add_cert(OpenSSL::X509::Certificate.new(ca_cert_data))
ssl_options = {
  cert_store: cert_store,
  verify_ssl: OpenSSL::SSL::VERIFY_PEER
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', "v1", ssl_options: ssl_options
)
```

For testing and development purpose you can disable the ssl check with:

```ruby
ssl_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', ssl_options: ssl_options
)
```

### Authentication

If you are using basic authentication or bearer tokens as described
[here](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/authentication.md) then you can specify one
of the following:

```ruby
auth_options = {
  username: 'username',
  password: 'password'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

or

```ruby
auth_options = {
  bearer_token: 'MDExMWJkMjItOWY1Ny00OGM5LWJlNDEtMjBiMzgxODkxYzYz'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

or

```ruby
auth_options = {
  bearer_token_file: '/path/to/token_file'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

#### Inside a Kubernetes cluster

The [recommended way to locate the API server](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod) within the pod is with the `kubernetes.default.svc` DNS name, which resolves to a Service IP which in turn will be routed to an API server.

The recommended way to authenticate to the API server is with a [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). kube-system associates a pod with a service account and a bearer token for that service account is placed into the filesystem tree of each container in that pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`.

If available, a certificate bundle is placed into the filesystem tree of each container at `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`, and should be used to verify the serving certificate of the API server.

For example:

```ruby
auth_options = {
  bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
}
ssl_options = {}
if File.exist?("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
  ssl_options[:ca_file] = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
end
client = Kubeclient::Client.new(
  'https://kubernetes.default.svc',
  'v1',
  auth_options: auth_options,
  ssl_options:  ssl_options
)
```

Finally, the default namespace to be used for namespaced API operations is placed in a file at `/var/run/secrets/kubernetes.io/serviceaccount/namespace` in each container. It is recommended that you use this namespace when issuing API commands below.

```ruby
namespace = File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace')
```
You can find information about tokens in [this guide](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod) and in [this reference](http://kubernetes.io/docs/admin/authentication/).

### Non-blocking IO

You can also use kubeclient with non-blocking sockets such as Celluloid::IO, see [here](https://github.com/httprb/http/wiki/Parallel-requests-with-Celluloid%3A%3AIO)
for details. For example:

```ruby
require 'celluloid/io'
socket_options = {
  socket_class: Celluloid::IO::TCPSocket,
  ssl_socket_class: Celluloid::IO::SSLSocket
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', socket_options: socket_options
)
```

This affects only `.watch_*` sockets, not one-off actions like `.get_*`, `.delete_*` etc.

### Proxies

You can also use kubeclient with an http proxy server such as tinyproxy. It can be entered as a string or a URI object.
For example:
```ruby
proxy_uri = URI::HTTP.build(host: "myproxyhost", port: 8443)
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', http_proxy_uri: proxy_uri
)
```

### Redirects

You can optionally not allow redirection with kubeclient. For example:

```ruby
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', http_max_redirects: 0
)
```

### Timeouts

Watching configures the socket to never time out (however, sooner or later all watches terminate).

One-off actions like `.get_*`, `.delete_*` have a configurable timeout:
```ruby
timeouts = {
  open: 10,  # unit is seconds
  read: nil  # nil means never time out
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', timeouts: timeouts
)
```

Default timeouts match `Net::HTTP` and `RestClient`, which unfortunately depends on ruby version:
- open was infinite up to ruby 2.2, 60 seconds in 2.3+.
- read is 60 seconds.

If you want ruby-independent behavior, always specify `:open`.

### Discovery

Discovery from the kube-apiserver is done lazily on method calls so it would not change behavior.

It can also  be done explicitly:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api', 'v1')
client.discover
```

It is possible to check the status of discovery

```ruby
unless client.discovered
  client.discover
end
```

### Kubeclient::Config

If you've been using `kubectl` and have a `.kube/config` file (possibly referencing other files in fields such as `client-certificate`), you can auto-populate a config object using `Kubeclient::Config`:

```ruby
# assuming $KUBECONFIG is one file, won't merge multiple like kubectl
config = Kubeclient::Config.read(ENV['KUBECONFIG'] || '/path/to/.kube/config')
```

This will lookup external files; relative paths will be resolved relative to the file's directory, if config refers to them with relative path.
This includes external [`exec:` credential plugins][exec] to be executed.

[exec]: https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins

You can also construct `Config` directly from nested data. For example if you have JSON or YAML config data in a variable:

```ruby
config = Kubeclient::Config.new(YAML.safe_load(yaml_text), nil)
# or
config = Kubeclient::Config.new(JSON.parse(json_text), nil)
```

The 2nd argument is a base directory for finding external files, if config refers to them with relative path.
Setting it to `nil` disables file lookups, and `exec:` execution - such configs will raise an exception.  (A config can be self-contained by using inline fields such as `client-certificate-data`.)

To create a client based on a Config object:

```ruby
# default context according to `current-context` field:
context = config.context
# or to use a specific context, by name:
context = config.context('default/192-168-99-100:8443/system:admin')

Kubeclient::Client.new(
  context.api_endpoint,
  'v1',
  ssl_options: context.ssl_options,
  auth_options: context.auth_options
)
```


#### Amazon EKS Credentials

On Amazon EKS by default the authentication method is IAM.  When running kubectl a temporary token is generated by shelling out to
the aws-iam-authenticator binary which is sent to authenticate the user.
See [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator).
To replicate that functionality, the `Kubeclient::AmazonEksCredentials` class can accept a set of IAM credentials and
contains a helper method to generate the authentication token for you.

This requires a set of gems which are _not_ included in
`kubeclient` dependencies (`aws-sigv4`) so you should add them to your bundle.
You will also require either the `aws-sdk` v2 or `aws-sdk-core` v3 gems to generate the required `Aws:Credentials` object to pass to this method.

To obtain a token:

```ruby
require 'aws-sdk-core'
# Use keys
credentials = Aws::Credentials.new(access_key, secret_key)
# Or a profile
credentials = Aws::SharedCredentials.new(profile_name: 'default').credentials

auth_options = {
  bearer_token: Kubeclient::AmazonEksCredentials.token(credentials, eks_cluster_name)
}
client = Kubeclient::Client.new(
  eks_cluster_https_endpoint, 'v1', auth_options: auth_options
)
```

Note that this returns a token good for one minute. If your code requires authorization for longer than that, you should plan to
acquire a new one, see [How to manually renew](#how-to-manually-renew-expired-credentials) section.

#### Google GCP credential plugin

If kubeconfig file has `user: {auth-provider: {name: gcp, cmd-path: ..., cmd-args: ..., token-key: ...}}`, the command will be executed to obtain a token.
(Normally this would be a `gcloud config config-helper` command.)

Note that this returns an expiring token. If your code requires authorization for a long time, you should plan to acquire a new one, see [How to manually renew](#how-to-manually-renew-expired-credentials) section.

#### Google's Application Default Credentials

On Google Compute Engine, Google App Engine, or Google Cloud Functions, as well as `gcloud`-configured systems
with [application default credentials](https://developers.google.com/identity/protocols/application-default-credentials),
kubeclient can use `googleauth` gem to authorize.

This requires the [`googleauth` gem](https://github.com/google/google-auth-library-ruby) that is _not_ included in
`kubeclient` dependencies so you should add it to your bundle.

If you use `Config.context(...).auth_options` and the kubeconfig file has `user: {auth-provider: {name: gcp}}`, but does not contain `cmd-path` key, kubeclient will automatically try this (raising LoadError if you don't have `googleauth` in your bundle).

Or you can obtain a token manually:

```ruby
require 'googleauth'

auth_options = {
  bearer_token: Kubeclient::GoogleApplicationDefaultCredentials.token
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

Note that this returns a token good for one hour. If your code requires authorization for longer than that, you should plan to
acquire a new one, see [How to manually renew](#how-to-manually-renew-expired-credentials) section.

#### OIDC Auth Provider

If the cluster you are using has OIDC authentication enabled you can use the `openid_connect` gem to obtain
id-tokens if the one in your kubeconfig has expired.

This requires the [`openid_connect` gem](https://github.com/nov/openid_connect) which is not included in
the `kubeclient` dependencies so should be added to your own applications bundle.

The OIDC Auth Provider will not perform the initial setup of your `$KUBECONFIG` file. You will need to use something
like [`dexter`](https://github.com/gini/dexter) in order to configure the auth-provider in your `$KUBECONFIG` file.

If you use `Config.context(...).auth_options` and the `$KUBECONFIG` file has user: `{auth-provider: {name: oidc}}`,
kubeclient will automatically obtain a token (or use `id-token` if still valid)

Tokens are typically short-lived (e.g. 1 hour) and the expiration time is determined by the OIDC Provider (e.g. Google).
If your code requires authentication for longer than that you should obtain a new token periodically, see [How to manually renew](#how-to-manually-renew-expired-credentials) section.

Note: id-tokens retrieved via this provider are not written back to the `$KUBECONFIG` file as they would be when
using `kubectl`.

#### How to manually renew expired credentials

Kubeclient [does not yet](https://github.com/abonas/kubeclient/issues/393) help with this.

The division of labor between `Config` and `Context` objects may change, for now please make no assumptions at which stage `exec:` and `auth-provider:` are handled and whether they're cached.
The currently guaranteed way to renew is create a new `Config` object.

The more painful part is that you'll then need to create new `Client` object(s) with the credentials from new config.
So repeat all of this:
```ruby
config = Kubeclient::Config.read(ENV['KUBECONFIG'] || '/path/to/.kube/config')
context = config.context
ssl_options = context.ssl_options
auth_options = context.auth_options

client = Kubeclient::Client.new(
    context.api_endpoint, 'v1',
    ssl_options: ssl_options, auth_options: auth_options
)
# and additional Clients if needed...
```

#### Security: Don't use config from untrusted sources

`Config.read` is catastrophically unsafe — it will execute arbitrary command lines specified by the config!

`Config.new(data, nil)` is better but Kubeclient was never reviewed for behaving safely with malicious / malformed config.
It might crash / misbehave in unexpected ways...

#### namespace

Additionally, the `config.context` object will contain a `namespace` attribute, if it was defined in the file.
It is recommended that you use this namespace when issuing API commands below.
This is the same behavior that is implemented by `kubectl` command.

You can read it as follows:

```ruby
puts config.context.namespace
```

### Supported kubernetes versions

We try to support the last 3 minor versions, matching the [official support policy for Kubernetes](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#supported-releases-and-component-skew).
Kubernetes 1.2 and below have known issues and are unsupported.
Kubernetes 1.3 presumed to still work although nobody is really testing on such old versions...

## Supported actions & examples:

Summary of main CRUD actions:

```
get_foos(namespace: 'namespace', **opts)  # namespaced collection
get_foos(**opts)                          # all namespaces or global collection

get_foo('name', 'namespace', opts)  # namespaced
get_foo('name', nil, opts)          # global

watch_foos(namespace: ns, **opts)   # namespaced collection
watch_foos(**opts)                  # all namespaces or global collection
watch_foos(namespace: ns, name: 'name', **opts)   # namespaced single object
watch_foos(name: 'name', **opts)                  # global single object

delete_foo('name', 'namespace', opts)    # namespaced
delete_foo('name', nil, opts)            # global

create_foo(Kubeclient::Resource.new({metadata: {name: 'name', namespace: 'namespace', ...}, ...}))
create_foo(Kubeclient::Resource.new({metadata: {name: 'name', ...}, ...}))  # global

update_foo(Kubeclient::Resource.new({metadata: {name: 'name', namespace: 'namespace', ...}, ...}))
update_foo(Kubeclient::Resource.new({metadata: {name: 'name', ...}, ...}))  # global

patch_foo('name', patch, 'namespace')    # namespaced
patch_foo('name', patch)                 # global

apply_foo(Kubeclient::Resource.new({metadata: {name: 'name', namespace: 'namespace', ...}, ...}), field_manager: 'myapp', **opts)
apply_foo(Kubeclient::Resource.new({metadata: {name: 'name', ...}, ...}), field_manager: 'myapp', **opts)  # global
```

These grew to be quite inconsistent :confounded:, see https://github.com/abonas/kubeclient/issues/312 and https://github.com/abonas/kubeclient/issues/332 for improvement plans.

### Get all instances of a specific entity type
Such as: `get_pods`, `get_secrets`, `get_services`, `get_nodes`, `get_replication_controllers`, `get_resource_quotas`, `get_limit_ranges`, `get_persistent_volumes`, `get_persistent_volume_claims`, `get_component_statuses`, `get_service_accounts`

```ruby
pods = client.get_pods
```

Get all entities of a specific type in a namespace:

```ruby
services = client.get_services(namespace: 'development')
```

You can get entities which have specific labels by specifying a parameter named `label_selector` (named `labelSelector` in Kubernetes server):

```ruby
pods = client.get_pods(label_selector: 'name=redis-master')
```

You can specify multiple labels (that option will return entities which have both labels:

```ruby
pods = client.get_pods(label_selector: 'name=redis-master,app=redis')
```

There is also [a limited ability to filter by *some* fields](https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/).  Which fields are supported is not documented, you can try and see if you get an error...
```ruby
client.get_pods(field_selector: 'spec.nodeName=master-0')
```

You can ask for entities at a specific version by specifying a parameter named `resource_version`:
```ruby
pods = client.get_pods(resource_version: '0')
```
but it's not guaranteed you'll get it.  See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions to understand the semantics.

With default (`as: :ros`) return format, the returned object acts like an array of the individual pods, but also supports a `.resourceVersion` method.

With `:parsed` and `:parsed_symbolized` formats, the returned data structure matches kubernetes list structure: it's a hash containing  `metadata` and `items` keys, the latter containing the individual pods.

#### Get all entities of a specific type in chunks

```ruby
continue = nil
loop do
  entities = client.get_pods(limit: 1_000, continue: continue)
  continue = entities.continue

  break if entities.last?
end
```

See https://kubernetes.io/docs/reference/using-api/api-concepts/#retrieving-large-results-sets-in-chunks for more information.

The continue tokens expire after a short amount of time, so similar to a watch if you don't request a subsequent page within aprox. 5 minutes of the previous page being returned the server will return a `410 Gone` error and the client must request the list from the start (i.e. omit the continue token for the next call).

Support for chunking was added in v1.9 so previous versions will ignore the option and return the full collection.

#### Get a specific instance of an entity (by name)
Such as: `get_service "service name"` , `get_pod "pod name"` , `get_replication_controller "rc name"`, `get_secret "secret name"`, `get_resource_quota "resource quota name"`, `get_limit_range "limit range name"` , `get_persistent_volume "persistent volume name"` , `get_persistent_volume_claim "persistent volume claim name"`, `get_component_status "component name"`, `get_service_account "service account name"`

The GET request should include the namespace name, except for nodes and namespaces entities.

```ruby
node = client.get_node "127.0.0.1"
```

```ruby
service = client.get_service "guestbook", 'development'
```

Note - Kubernetes doesn't work with the uid, but rather with the 'name' property.
Querying with uid causes 404.

#### Getting raw responses

To avoid overhead from parsing and building `RecursiveOpenStruct` objects for each reply, pass the `as: :raw` option when initializing `Kubeclient::Client` or when calling `get_` / `watch_` methods.
The result can then be printed, or searched with a regex, or parsed via `JSON.parse(r)`.

```ruby
client = Kubeclient::Client.new(as: :raw)
```

or

```ruby
pods = client.get_pods as: :raw
node = client.get_node "127.0.0.1", as: :raw
```

Other formats are:
 - `:ros` (default) for `RecursiveOpenStruct`
 - `:parsed` for `JSON.parse`
 - `:parsed_symbolized` for `JSON.parse(..., symbolize_names: true)`

### Watch — Receive entities updates

See https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes for an overview.

It is possible to receive live update notices watching the relevant entities:

```ruby
client.watch_pods do |notice|
  # process notice data
end
```

The notices have `.type` field which may be `'ADDED'`, `'MODIFIED'`, `'DELETED'`, or currently `'ERROR'`, and an `.object` field containing the object.  **UPCOMING CHANGE**: In next major version, we plan to raise exceptions instead of passing on ERROR into the block.

For namespaced entities, the default watches across all namespaces, and you can specify `client.watch_secrets(namespace: 'foo')` to only watch in a single namespace.

You can narrow down using `label_selector:` and `field_selector:` params, like with `get_pods` methods.

You can also watch a single object by specifying `name:` e.g. `client.watch_nodes(name: 'gandalf')` (not namespaced so a name is enough) or `client.watch_pods(namespace: 'foo', name: 'bar')` (namespaced, need both params).
Note the method name is still plural!  There is no `watch_pod`, only `watch_pods`.  The yielded "type" remains the same — watch notices, it's just they'll always refer to the same object.

You can use `as:` param to control the format of the yielded notices.

#### All watches come to an end!

While nominally the watch block *looks* like an infinite loop, that's unrealistic.  Network connections eventually get severed, and kubernetes apiserver is known to terminate watches.

Unfortunately, this sometimes raises an exception and sometimes the loop just exits.  **UPCOMING CHANGE**: In next major version, non-deliberate termination will always raise an exception; the block will only exit silenty if stopped deliberately.

#### Deliberately stopping a watch

You can use `break` or `return` inside the watch block.

It is possible to interrupt the watcher from another thread with:

```ruby
watcher = client.watch_pods

watcher.each do |notice|
  # process notice data
end
# <- control will pass here after .finish is called

### In another thread ###
watcher.finish
```

#### Starting watch version

You can specify version to start from, commonly used in "List+Watch" pattern:
```
list = client.get_pods
collection_version = list.resourceVersion
# or with other return formats:
list = client.get_pods(as: :parsed)
collection_version = list['metadata']['resourceVersion']

# note spelling resource_version vs resourceVersion.
client.watch_pods(resource_version: collection_version) do |notice|
  # process notice data
end
```
It's important to understand [the effects of unset/0/specific resource_version](https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions) as it modifies the behavior of the watch — in some modes you'll first see a burst of synthetic 'ADDED' notices for all existing objects.

If you re-try a terminated watch again without specific resourceVersion, you might see previously seen notices again, and might miss some events.

To attempt resuming a watch from same point, you can try using last resourceVersion observed during the watch.  Or do list+watch again.

Whenever you ask for a specific version, you must be prepared for an 410 "Gone" error if the server no longer recognizes it.

#### Watch events about a particular object
Events are [entities in their own right](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#event-v1-core).
You can use the `field_selector` option as part of the watch methods.

```ruby
client.watch_events(namespace: 'development', field_selector: 'involvedObject.name=redis-master') do |notice|
  # process notice date
end
```

### Delete an entity (by name)

For example: `delete_pod "pod name"` , `delete_replication_controller "rc name"`, `delete_node "node name"`, `delete_secret "secret name"`

Input parameter - name (string) specifying service name, pod name, replication controller name.

```ruby
deleted = client.delete_service("redis-service")
```

If you want to cascade delete, for example a deployment, you can use the `delete_options` parameter.

```ruby
deployment_name = 'redis-deployment'
namespace = 'default'
delete_options = Kubeclient::Resource.new(
    apiVersion: 'meta/v1',
    gracePeriodSeconds: 0,
    kind: 'DeleteOptions',
    propagationPolicy: 'Foreground' # Orphan, Foreground, or Background
)
client.delete_deployment(deployment_name, namespace, delete_options: delete_options)
```

### Create an entity
For example: `create_pod pod_object`, `create_replication_controller rc_obj`, `create_secret secret_object`, `create_resource_quota resource_quota_object`, `create_limit_range limit_range_object`, `create_persistent_volume persistent_volume_object`, `create_persistent_volume_claim persistent_volume_claim_object`, `create_service_account service_account_object`

Input parameter - object of type `Service`, `Pod`, `ReplicationController`.

The below example is for v1

```ruby
service = Kubeclient::Resource.new
service.metadata = {}
service.metadata.name = "redis-master"
service.metadata.namespace = 'staging'
service.spec = {}
service.spec.ports = [{
  'port' => 6379,
  'targetPort' => 'redis-server'
}]
service.spec.selector = {}
service.spec.selector.name = "redis"
service.spec.selector.role = "master"
service.metadata.labels = {}
service.metadata.labels.app = 'redis'
service.metadata.labels.role = 'slave'
client.create_service(service)
```

### Update an entity
For example: `update_pod`, `update_service`, `update_replication_controller`, `update_secret`, `update_resource_quota`, `update_limit_range`, `update_persistent_volume`, `update_persistent_volume_claim`, `update_service_account`

Input parameter - object of type `Pod`, `Service`, `ReplicationController` etc.

The below example is for v1

```ruby
updated = client.update_service(service1)
```

### Patch an entity (by name)
For example: `patch_pod`, `patch_service`, `patch_secret`, `patch_resource_quota`, `patch_persistent_volume`

Input parameters - name (string) specifying the entity name, patch (hash) to be applied to the resource, optional: namespace name (string)

The PATCH request should include the namespace name, except for nodes and namespaces entities.

The below example is for v1

```ruby
patched = client.patch_pod("docker-registry", {metadata: {annotations: {key: 'value'}}}, "default")
```

`patch_#{entity}` is called using a [strategic merge patch](https://kubernetes.io/docs/tasks/run-application/update-api-object-kubectl-patch/#notes-on-the-strategic-merge-patch). `json_patch_#{entity}` and `merge_patch_#{entity}` are also available that use JSON patch and JSON merge patch, respectively. These strategies are useful for resources that do not support strategic merge patch, such as Custom Resources. Consult the [Kubernetes docs](https://kubernetes.io/docs/tasks/run-application/update-api-object-kubectl-patch/#use-a-json-merge-patch-to-update-a-deployment) for more information about the different patch strategies.

### Apply an entity

This is similar to `kubectl apply --server-side` (kubeclient doesn't implement logic for client-side apply). See https://kubernetes.io/docs/reference/using-api/api-concepts/#server-side-apply

For example: `apply_pod`

Input parameters - resource (Kubeclient::Resource) representing the desired state of the resource, field_manager (String) to identify the system managing the state of the resource, force (Boolean) whether or not to override a field managed by someone else.

Example:

```ruby
service = Kubeclient::Resource.new(
  metadata: {
    name: 'redis-master',
    namespace: 'staging',
  },
  spec: {
    ...
  }
)

client.apply_service(service, field_manager: 'myapp')
```

### Get all entities of all types : all_entities

Makes requests for all entities of each discovered kind (in this client's API group).  This method is a convenience method instead of calling each entity's get method separately.

Returns a hash with keys being the *singular* entity kind, in lowercase underscore style.  For example for core API group may return keys `"node'`, `"secret"`, `"service"`, `"pod"`, `"replication_controller"`, `"namespace"`, `"resource_quota"`, `"limit_range"`, `"endpoint"`, `"event"`, `"persistent_volume"`, `"persistent_volume_claim"`, `"component_status"`, `"service_account"`. Each key points to an EntityList of same type.

```ruby
client.all_entities
```

### Get a proxy URL
You can get a complete URL for connecting a kubernetes entity via the proxy.

```ruby
client.proxy_url('service', 'srvname', 'srvportname', 'ns')
# => "https://localhost.localdomain:8443/api/v1/proxy/namespaces/ns/services/srvname:srvportname"
```

Note the third parameter, port, is a port name for services and an integer for pods:

```ruby
client.proxy_url('pod', 'podname', 5001, 'ns')
# => "https://localhost.localdomain:8443/api/v1/namespaces/ns/pods/podname:5001/proxy"
```

### Get the logs of a pod
You can get the logs of a running pod, specifying the name of the pod and the
namespace where the pod is running:

```ruby
client.get_pod_log('pod-name', 'default')
# => "Running...\nRunning...\nRunning...\n"
```

If that pod has more than one container, you must specify the container:

```ruby
client.get_pod_log('pod-name', 'default', container: 'ruby')
# => "..."
```

If a container in a pod terminates, a new container is started, and you want to
retrieve the logs of the dead container, you can pass in the `:previous` option:

```ruby
client.get_pod_log('pod-name', 'default', previous: true)
# => "..."
```

Kubernetes can add timestamps to every log line or filter by lines time:
```ruby
client.get_pod_log('pod-name', 'default', timestamps: true, since_time: '2018-04-27T18:30:17.480321984Z')
# => "..."
```
`since_time` can be a a `Time`, `DateTime` or `String` formatted according to RFC3339

Kubernetes can fetch a specific number of lines from the end of the logs:
```ruby
client.get_pod_log('pod-name', 'default', tail_lines: 10)
# => "..."
```

Kubernetes can fetch a specific number of bytes from the log, but the exact size is not guaranteed and last line may not be terminated:
```ruby
client.get_pod_log('pod-name', 'default', limit_bytes: 10)
# => "..."
```

You can also watch the logs of a pod to get a stream of data:

```ruby
client.watch_pod_log('pod-name', 'default', container: 'ruby') do |line|
  puts line
end
```

### OpenShift: Process a template
Returns a processed template containing a list of objects to create.
Input parameter - template (hash)
Besides its metadata, the template should include a list of objects to be processed and a list of parameters
to be substituted. Note that for a required parameter that does not provide a generated value, you must supply a value.

##### Note: This functionality is not supported by K8s at this moment. See the following [issue](https://github.com/kubernetes/kubernetes/issues/23896)

```ruby
client.process_template template
```

## Upgrading

Kubeclient release versioning follows [SemVer](https://semver.org/).
See [CHANGELOG.md](CHANGELOG.md) for full changelog.

#### past version 4.0

Old kubernetes versions < 1.3 no longer supported.

#### past version 3.0

Ruby versions < 2.2 are no longer supported

Specific entity classes mentioned in [past version 1.2.0](#past_version_1.2.0) have been dropped.
Return values and expected classes are always Kubeclient::Resource.
Checking the type of a resource can be done using:
```
> pod.kind
=> "Pod"
```

update_* delete_* and patch_* now return a RecursiveOpenStruct like the get_* methods

The `Kubeclient::Client` class raises `Kubeclient::HttpError` or subclasses now. Catching `KubeException` still works but is deprecated.

`Kubeclient::Config#context` raises `KeyError` instead of `RuntimeError` for non-existent context name.

<a name="past_version_1.2.0">

#### past version 1.2.0
Replace Specific Entity class references:

```ruby
Kubeclient::Service
```

with the generic

```ruby
Kubeclient::Resource.new
```

Where ever possible.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/kubeclient/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes with `rake test rubocop`, add new tests if needed.
4. If you added a new functionality, add it to README
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## Tests

This client is tested with Minitest and also uses VCR recordings in some tests.
Please run all tests before submitting a Pull Request, and add new tests for new functionality.

Running tests:
```ruby
rake test
```
