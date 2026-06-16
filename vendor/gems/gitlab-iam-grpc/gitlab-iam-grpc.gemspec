# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = 'gitlab-iam-grpc'
  spec.version = '0.1.0'
  spec.authors = ['GitLab']
  spec.summary = 'gRPC client stubs for the GitLab IAM service'
  spec.description = 'Provides gRPC client stubs for communicating with the GitLab IAM service'
  spec.homepage = 'https://gitlab.com/gitlab-org/auth/iam'
  spec.license = 'MIT'
  
  spec.files = Dir['lib/**/*']

  spec.require_paths = ['lib']

  spec.add_dependency 'grpc'
  spec.add_dependency 'google-protobuf'
end
