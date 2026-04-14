# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_url: 'https://bitbucket.org',
      import_source: 'my-workspace/my-repo',
      import_data_attributes: {
        credentials: { 'token' => 'some-token' }
      }
    )
  end

  let(:importer_double) { instance_double(Gitlab::BitbucketImport::Importers::RepositoryImporter) }

  subject(:worker) { described_class.new }

  before do
    allow(Gitlab::BitbucketImport::Importers::RepositoryImporter).to receive(:new).and_return(importer_double)
    allow(importer_double).to receive(:execute).and_return(true)
  end

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  it 'executes the importer' do
    allow_next_instance_of(Bitbucket::Client) do |client|
      allow(client).to receive_messages(last_pull_request: nil, last_issue: nil)
    end

    expect(importer_double).to receive(:execute)

    worker.perform(project.id)
  end

  context 'when the importer fails' do
    it 'does not schedule the next stage and raises error' do
      exception = StandardError.new('Error')

      allow_next_instance_of(Bitbucket::Client) do |client|
        allow(client).to receive_messages(last_pull_request: nil, last_issue: nil)
      end

      allow(importer_double).to receive(:execute).and_raise(exception)

      expect(Gitlab::Import::ImportFailureService)
        .to receive(:track).with(
          project_id: project.id,
          exception: exception,
          error_source: described_class.name,
          fail_import: false
        ).and_call_original

      expect { worker.perform(project.id) }
        .to not_change { Gitlab::BitbucketImport::Stage::ImportUsersWorker.jobs.size }
        .and raise_error(exception)
    end
  end

  it 'enqueues ImportUsersWorker' do
    allow_next_instance_of(Bitbucket::Client) do |client|
      allow(client).to receive_messages(last_pull_request: nil, last_issue: nil)
    end

    expect(Gitlab::BitbucketImport::Stage::ImportUsersWorker).to receive(:perform_async).with(project.id)
      .and_return(true).once

    worker.perform(project.id)
  end

  describe 'IID pre-allocation' do
    let(:pull_request) { instance_double(Bitbucket::Representation::PullRequest, iid: 42) }
    let(:issue) { instance_double(Bitbucket::Representation::Issue, iid: 10) }

    context 'when both pull requests and issues exist on the source' do
      it 'pre-allocates both merge request and issue IIDs' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(pull_request)
          allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(issue)
        end

        preallocator = instance_double(Gitlab::Import::IidPreallocator)
        expect(Gitlab::Import::IidPreallocator).to receive(:new)
          .with(project, { merge_requests: 42, issues: 10 })
          .and_return(preallocator)
        expect(preallocator).to receive(:execute)

        worker.perform(project.id)
      end
    end

    context 'when only pull requests exist on the source' do
      it 'pre-allocates only merge request IIDs' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(pull_request)
          allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(nil)
        end

        preallocator = instance_double(Gitlab::Import::IidPreallocator)
        expect(Gitlab::Import::IidPreallocator).to receive(:new)
          .with(project, { merge_requests: 42 })
          .and_return(preallocator)
        expect(preallocator).to receive(:execute)

        worker.perform(project.id)
      end
    end

    context 'when only issues exist on the source' do
      it 'pre-allocates only issue IIDs' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(nil)
          allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(issue)
        end

        preallocator = instance_double(Gitlab::Import::IidPreallocator)
        expect(Gitlab::Import::IidPreallocator).to receive(:new)
          .with(project, { issues: 10 })
          .and_return(preallocator)
        expect(preallocator).to receive(:execute)

        worker.perform(project.id)
      end
    end

    context 'when there are no pull requests or issues on the source' do
      it 'does not pre-allocate IIDs' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(nil)
          allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(nil)
        end

        expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

        worker.perform(project.id)
      end
    end

    context 'when merge request IIDs have already been allocated' do
      before do
        create(:internal_id, project: project, usage: :merge_requests, last_value: 10)
      end

      it 'does not fetch the last pull request from the API' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(nil)
          expect(client).not_to receive(:last_pull_request)
        end

        worker.perform(project.id)
      end
    end

    context 'when issue IIDs have already been allocated' do
      before do
        create(:internal_id, project: project, usage: :issues, last_value: 5)
      end

      it 'does not fetch the last issue from the API' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(nil)
          expect(client).not_to receive(:last_issue)
        end

        worker.perform(project.id)
      end
    end

    context 'when the source returns an invalid IID' do
      using RSpec::Parameterized::TableSyntax

      where(:iid_value) do
        [
          0,
          -1,
          (2**31),
          'not_a_number'
        ]
      end

      with_them do
        let(:pull_request) { instance_double(Bitbucket::Representation::PullRequest, iid: iid_value) }

        it 'does not pre-allocate IIDs for the invalid value' do
          allow_next_instance_of(Bitbucket::Client) do |client|
            allow(client).to receive(:last_pull_request).with('my-workspace/my-repo').and_return(pull_request)
            allow(client).to receive(:last_issue).with('my-workspace/my-repo').and_return(nil)
          end

          expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

          worker.perform(project.id)
        end
      end
    end

    it 'does not suppress Bitbucket API errors' do
      allow_next_instance_of(Bitbucket::Client) do |client|
        allow(client).to receive(:last_pull_request).and_raise(StandardError, 'connection error')
      end

      expect { worker.perform(project.id) }.to raise_error(StandardError, 'connection error')
    end

    it 'still schedules the next stage after pre-allocation' do
      allow_next_instance_of(Bitbucket::Client) do |client|
        allow(client).to receive_messages(last_pull_request: pull_request, last_issue: issue)
      end
      allow_next_instance_of(Gitlab::Import::IidPreallocator) do |preallocator|
        allow(preallocator).to receive(:execute)
      end

      expect(Gitlab::BitbucketImport::Stage::ImportUsersWorker).to receive(:perform_async)
        .with(project.id)

      worker.perform(project.id)
    end
  end
end
