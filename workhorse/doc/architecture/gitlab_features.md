# Features that rely on Workhorse

Workhorse itself is not a feature, but there are several features in
GitLab that would not work efficiently without Workhorse.

To put the efficiency benefit in context, consider that in 2020Q3 on
GitLab.com [we see][thanos] Rails application threads using on average
about 200MB of RSS vs about 200KB for Workhorse goroutines.

Examples of features that rely on Workhorse:

## 1. `git clone` and `git push` over HTTP

Git clone, pull and push are slow because they transfer large amounts
of data and because each is CPU intensive on the GitLab side. Without
Workhorse, HTTP access to Git repositories would compete with regular
web access to the application, requiring us to run way more Rails
application servers.

## 2. CI runner long polling

GitLab CI runners fetch new CI jobs by polling the GitLab server.
Workhorse acts as a kind of "waiting room" where CI runners can sit
and wait for new CI jobs. Because of Go's efficiency we can fit a lot
of runners in the waiting room at little cost. Without this waiting
room mechanism we would have to add a lot more Rails server capacity.

## 3. File uploads and downloads

File uploads and downloads may be slow either because the file is
large or because the user's connection is slow. Workhorse can handle
the slow part for Rails. This improves the efficiency of features such
as CI artifacts, package repositories, LFS objects, etc.

## 4. Websocket proxying

Features such as the web terminal require a long lived connection
between the user's web browser and a container inside GitLab that is
not directly accessible from the internet. Dedicating a Rails
application thread to proxying such a connection would cost much more
memory than it costs to have Workhorse look after it.

## Quick facts (how does Workhorse work)

- Workhorse can handle some requests without involving Rails at all:
  for example, JavaScript files and CSS files are served straight
  from disk.
- Workhorse can modify responses sent by Rails: for example if you use
  `send_file` in Rails then GitLab Workhorse will open the file on
  disk and send its contents as the response body to the client.
- Workhorse can take over requests after asking permission from Rails.
  Example: handling `git clone`.
- Workhorse can modify requests before passing them to Rails. Example:
  when handling a Git LFS upload Workhorse first asks permission from
  Rails, then it stores the request body in a tempfile, then it sends
  a modified request containing the tempfile path to Rails.
- Workhorse can manage long-lived WebSocket connections for Rails.
  Example: handling the terminal websocket for environments.
- Workhorse does not connect to PostgreSQL, only to Rails and (optionally) Redis.
- We assume that all requests that reach Workhorse pass through an
  upstream proxy such as NGINX or Apache first.
- Workhorse does not accept HTTPS connections.
- Workhorse does not clean up idle client connections.
- We assume that all requests to Rails pass through Workhorse.

For more information see ['A brief history of GitLab Workhorse'][brief-history-blog].

[thanos]: https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=sum(ruby_process_resident_memory_bytes%7Bapp%3D%22webservice%22%2Cenv%3D%22gprd%22%2Crelease%3D%22gitlab%22%7D)%20%2F%20sum(puma_max_threads%7Bapp%3D%22webservice%22%2Cenv%3D%22gprd%22%2Crelease%3D%22gitlab%22%7D)&g0.tab=1&g1.range_input=1h&g1.max_source_resolution=0s&g1.expr=sum(go_memstats_sys_bytes%7Bapp%3D%22webservice%22%2Cenv%3D%22gprd%22%2Crelease%3D%22gitlab%22%7D)%2Fsum(go_goroutines%7Bapp%3D%22webservice%22%2Cenv%3D%22gprd%22%2Crelease%3D%22gitlab%22%7D)&g1.tab=1
[brief-history-blog]: https://about.gitlab.com/2016/04/12/a-brief-history-of-gitlab-workhorse/
