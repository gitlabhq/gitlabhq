# frozen_string_literal: true

require_relative "lib/gitlab/duo_workflow_service/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-duo-workflow-service-client"
  spec.version = Gitlab::DuoWorkflowService::VERSION
  spec.authors = ["group::ai framework"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "Client library to interact with the Duo Workflow Service"
  spec.homepage = "https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency "grpc"
  spec.add_development_dependency "gitlab-styles", "~> 10.1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized", "~> 1.0.2"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency 'grpc-tools'
end
