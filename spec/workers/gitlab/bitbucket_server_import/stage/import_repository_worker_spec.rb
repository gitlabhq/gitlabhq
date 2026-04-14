# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods

  describe '#perform' do
    before do
      allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::RepositoryImporter) do |importer|
        allow(importer).to receive(:execute)
      end
    end

    context 'when the import succeeds' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).and_return(nil)
        end
      end

      it 'schedules the next stage' do
        expect(Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker).to receive(:perform_async)
          .with(project.id)

        worker.perform(project.id)
      end

      it 'logs stage start and finish' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'starting stage', project_id: project.id))
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'stage finished', project_id: project.id))

        worker.perform(project.id)
      end
    end

    context 'when project does not exists' do
      it 'does not call importer' do
        expect(Gitlab::BitbucketServerImport::Importers::RepositoryImporter).not_to receive(:new)

        worker.perform(-1)
      end
    end

    context 'when project import state is not `started`' do
      it 'does not call importer' do
        project = create(:project, :import_canceled)

        expect(Gitlab::BitbucketServerImport::Importers::RepositoryImporter).not_to receive(:new)

        worker.perform(project.id)
      end
    end

    context 'when the importer fails' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).and_return(nil)
        end
      end

      it 'does not schedule the next stage and raises error' do
        exception = StandardError.new('Error')

        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::RepositoryImporter) do |importer|
          allow(importer).to receive(:execute).and_raise(exception)
        end

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            fail_import: false
          ).and_call_original

        expect { worker.perform(project.id) }
          .to not_change { Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker.jobs.size }
          .and raise_error(exception)
      end
    end

    describe 'IID pre-allocation' do
      let(:pull_request) do
        instance_double(BitbucketServer::Representation::PullRequest, iid: 42)
      end

      it 'pre-allocates merge request IIDs when pull requests exist on the source' do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).with('key', 'slug').and_return(pull_request)
        end

        preallocator = instance_double(Gitlab::Import::IidPreallocator)
        expect(Gitlab::Import::IidPreallocator).to receive(:new)
          .with(project, { merge_requests: 42 })
          .and_return(preallocator)
        expect(preallocator).to receive(:execute)

        worker.perform(project.id)
      end

      it 'does not pre-allocate when there are no pull requests on the source' do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).with('key', 'slug').and_return(nil)
        end

        expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

        worker.perform(project.id)
      end

      context 'when merge request IIDs have already been allocated' do
        before do
          create(:internal_id, project: project, usage: :merge_requests, last_value: 10)
        end

        it 'does not make a Bitbucket Server API call' do
          expect(BitbucketServer::Client).not_to receive(:new)

          worker.perform(project.id)
        end

        it 'does not call IidPreallocator' do
          expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

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
          let(:pull_request) do
            instance_double(BitbucketServer::Representation::PullRequest, iid: iid_value)
          end

          it 'does not pre-allocate IIDs' do
            allow_next_instance_of(BitbucketServer::Client) do |client|
              allow(client).to receive(:last_pull_request).with('key', 'slug').and_return(pull_request)
            end

            expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

            worker.perform(project.id)
          end
        end
      end

      it 'does not suppress Bitbucket Server API errors' do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).and_raise(StandardError, 'connection error')
        end

        expect { worker.perform(project.id) }.to raise_error(StandardError, 'connection error')
      end

      it 'still schedules the next stage after pre-allocation' do
        allow_next_instance_of(BitbucketServer::Client) do |client|
          allow(client).to receive(:last_pull_request).and_return(pull_request)
        end
        allow_next_instance_of(Gitlab::Import::IidPreallocator) do |preallocator|
          allow(preallocator).to receive(:execute)
        end

        expect(Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker).to receive(:perform_async)
          .with(project.id)

        worker.perform(project.id)
      end
    end
  end
end
