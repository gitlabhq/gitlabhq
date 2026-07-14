# frozen_string_literal: true

# Shared contexts for Gitaly unavailable error stubs used in request specs.
# These contexts define the `allow_gitaly_to_raise_error` let block that is
# expected by the shared examples in handles_gitaly_errors_shared_examples.rb.
#
# Usage:
#   describe '#show' do
#     include_context 'when Repository#blob_at raises Gitaly error'
#     let(:make_request) { get project_blob_path(project, 'master/README.md') }
#     it_behaves_like 'handles Gitaly errors for request specs'
#   end

RSpec.shared_context 'when Repository#blob_at raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_at)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when Repository#blob_at_branch raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_at_branch)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when Repository#commit_by raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:commit_by)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when Gitlab::Git::Commit.find raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow(Gitlab::Git::Commit).to receive(:find)
      .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
  end
end

RSpec.shared_context 'when Repository#commits raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:commits)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when CompareService#execute raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(CompareService) do |service|
      allow(service).to receive(:execute)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when RefsFinder#execute raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Gitlab::Git::Finders::RefsFinder) do |finder|
      allow(finder).to receive(:execute)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end
  end
end

RSpec.shared_context 'when Conflict::Resolver#conflicts raises Gitaly error' do
  let(:allow_gitaly_to_raise_error) do
    allow_next_instance_of(Gitlab::Git::Conflict::Resolver) do |resolver|
      allow(resolver).to receive(:conflicts) do
        raise GRPC::Unavailable, 'Gitaly unavailable'
      rescue GRPC::Unavailable
        raise Gitlab::Git::CommandError, 'Gitaly unavailable'
      end
    end
  end
end
