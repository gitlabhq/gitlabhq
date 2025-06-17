# Duo Workflow Service Client Gem

This Ruby Gem is meant to initialize a client to the Duo Workflow Service.

This Gem is generated via GRPC from the repository <https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist>.

The gem's single source of truth is the version in the Duo Workflow Service repository, because that is where the `.proto` files that the gem is based on live.

## How to use the gem

To test the gem locally:

1. Run the Duo Workflow Service server.

   ```shell
   poetry run python -m duo_workflow_service.server
   ```

1. Invoke the client in a Rails console.

   ```shell
   gdk rails console
   ```

   ```ruby
   Ai::DuoWorkflow::DuoWorkflowService::Client.new(duo_workflow_service_url: "localhost:50052", current_user: User.first, secure: false).generate_token
   ```

## How to update the gem

The gem must be built manually and then copied over to [GitLab](https://gitlab.com/gitlab-org/gitlab), which is where it is used.

We may [automate this process](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1090) later.

How to do this:

### Update the gem in the Duo Workflow Service repository

1. Ensure the proto files are up to date.

   ```shell
   make gen-proto-ruby
   ```

1. Update the Gem version in `clients/ruby/lib/gitlab/duo_workflow_service/version.rb` to bump the version according to [semantic versioning](https://semver.org/) rules.
1. Commit these changes and open a Merge Request.

### Update the gem in the GitLab repository

1. Copy over the update gem source files.

   ```shell
   cd <gdk-root>
   rm -rf gitlab/vendor/gems/gitlab-duo-workflow-service-client/*
   cp -R gitlab-ai-gateway/clients/ruby/. gitlab/vendor/gems/gitlab-duo-workflow-service-client
   ```

1. Update the `Gemfile` so that `gitlab-duo-workflow-service-client` points to the version of the gem in the latest updates.
1. Run `bundle` to update `Gemfile.lock`
1. Commit these changes and open a Merge Request.
