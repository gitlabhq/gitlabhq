# ruby-cloud-profiler

An implementation of [Google Cloud Profiler](https://cloud.google.com/profiler/docs)
for Ruby.

This project is not officially supported or endorsed by Google in any way.

Under the hood, the agent uses [Stackprof](https://github.com/tmm1/stackprof)
to collect the profiling data, and then converts it to
[the pprof format](https://github.com/google/pprof/blob/master/proto/profile.proto)
expected by Cloud Profiler. The Cloud Profiler API doesn't have pretty HTML
documentation, but is described
[in the googleapis specification](https://github.com/googleapis/googleapis/blob/master/google/devtools/cloudprofiler/v2/profiler.proto)
which creates
[generated code in google-api-ruby-client](https://github.com/googleapis/google-api-ruby-client/tree/master/generated/google/apis/cloudprofiler_v2).

To use, you need to decide what to name your service and you need a Google
Cloud project ID:

    require 'cloud_profiler_agent'
    agent = CloudProfilerAgent::Agent.new(service: 'my-service', project_id: 'my-project-id')
    agent.start

This will start a background thread that will merrily poll the Cloud Profiler
API to see what kinds of profiles it should collect, and when. Then it will run
stackprof, and upload the profiles.

Note: the agent can only profile its own process. If your Ruby application is
running from a webserver that forks subprocesses, then you'll need to somehow
arrange to start the agent in the subprocess.
