# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportRepositoryWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:client) { instance_double(Gitlab::GithubImport::Client) }
    let(:issue_options) { { state: 'all', sort: 'number', direction: 'desc', per_page: '1' } }
    let(:pr_options) { { state: 'all', sort: 'created', direction: 'desc', per_page: '1' } }

    before do
      allow_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
        allow(instance).to receive(:execute).and_return(true)
      end
    end

    context 'when the import succeeds' do
      it 'pre-allocates IIDs for issues, merge requests, and milestones' do
        expect(client).to receive(:each_object).with(
          :issues, project.import_source, issue_options
        ).and_return([{ number: 5 }].each)

        expect(client).to receive(:each_object).with(
          :pull_requests, project.import_source, pr_options
        ).and_return([{ number: 8 }].each)

        expect(client).to receive(:each_object).with(
          :milestones, project.import_source, { state: 'all', per_page: '100' }
        ).and_yield({ number: 1 }).and_yield({ number: 3 }).and_yield({ number: 2 })

        preallocator = instance_double(Gitlab::Import::IidPreallocator)
        expect(Gitlab::Import::IidPreallocator).to receive(:new).with(
          project, { issues: 5, merge_requests: 8, project_milestones: 3 }
        ).and_return(preallocator)
        expect(preallocator).to receive(:execute)

        expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
          .to receive(:perform_async)
          .with(project.id)

        worker.import(client, project)
      end

      context 'when there are no issues on GitHub' do
        it 'does not include issues in max_iids' do
          expect(client).to receive(:each_object).with(
            :issues, project.import_source, issue_options
          ).and_return([nil].each)

          expect(client).to receive(:each_object).with(
            :pull_requests, project.import_source, pr_options
          ).and_return([{ number: 4 }].each)

          expect(client).to receive(:each_object).with(
            :milestones, project.import_source, { state: 'all', per_page: '100' }
          ).and_yield({ number: 3 })

          preallocator = instance_double(Gitlab::Import::IidPreallocator)
          expect(Gitlab::Import::IidPreallocator).to receive(:new).with(
            project, { merge_requests: 4, project_milestones: 3 }
          ).and_return(preallocator)
          expect(preallocator).to receive(:execute)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'when there are no pull requests on GitHub' do
        it 'does not include merge_requests in max_iids' do
          expect(client).to receive(:each_object).with(
            :issues, project.import_source, issue_options
          ).and_return([{ number: 10 }].each)

          expect(client).to receive(:each_object).with(
            :pull_requests, project.import_source, pr_options
          ).and_return([nil].each)

          expect(client).to receive(:each_object).with(
            :milestones, project.import_source, { state: 'all', per_page: '100' }
          ).and_yield({ number: 2 })

          preallocator = instance_double(Gitlab::Import::IidPreallocator)
          expect(Gitlab::Import::IidPreallocator).to receive(:new).with(
            project, { issues: 10, project_milestones: 2 }
          ).and_return(preallocator)
          expect(preallocator).to receive(:execute)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'when there are no milestones on GitHub' do
        it 'does not include milestones in max_iids' do
          expect(client).to receive(:each_object).with(
            :issues, project.import_source, issue_options
          ).and_return([{ number: 10 }].each)

          expect(client).to receive(:each_object).with(
            :pull_requests, project.import_source, pr_options
          ).and_return([{ number: 7 }].each)

          expect(client).to receive(:each_object).with(
            :milestones, project.import_source, { state: 'all', per_page: '100' }
          )

          preallocator = instance_double(Gitlab::Import::IidPreallocator)
          expect(Gitlab::Import::IidPreallocator).to receive(:new).with(
            project, { issues: 10, merge_requests: 7 }
          ).and_return(preallocator)
          expect(preallocator).to receive(:execute)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'when retrying and IIDs have already been allocated' do
        it 'does not make GitHub API calls or re-allocate IIDs' do
          allow(InternalId).to receive(:exists?)
            .with(namespace: project.project_namespace, usage: :issues).and_return(true)
          allow(InternalId).to receive(:exists?)
            .with(project: project, usage: :merge_requests).and_return(true)
          allow(InternalId).to receive(:exists?)
            .with(project: project, usage: :milestones).and_return(true)

          expect(client).not_to receive(:each_object)
          expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end

        it 'allocates remaining resources when only some IIDs exist' do
          allow(InternalId).to receive(:exists?)
            .with(namespace: project.project_namespace, usage: :issues).and_return(true)
          allow(InternalId).to receive(:exists?)
            .with(project: project, usage: :merge_requests).and_return(true)
          allow(InternalId).to receive(:exists?)
            .with(project: project, usage: :milestones).and_return(false)

          expect(client).not_to receive(:each_object).with(:issues, anything, anything)
          expect(client).not_to receive(:each_object).with(:pull_requests, anything, anything)
          expect(client).to receive(:each_object).with(
            :milestones, project.import_source, { state: 'all', per_page: '100' }
          ).and_yield({ number: 5 })

          preallocator = instance_double(Gitlab::Import::IidPreallocator)
          expect(Gitlab::Import::IidPreallocator).to receive(:new).with(
            project, { project_milestones: 5 }
          ).and_return(preallocator)
          expect(preallocator).to receive(:execute)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end

      context 'when the repository has no issues, pull requests, or milestones' do
        it 'does not call IidPreallocator' do
          expect(client).to receive(:each_object).with(
            :issues, project.import_source, issue_options
          ).and_return([nil].each)

          expect(client).to receive(:each_object).with(
            :pull_requests, project.import_source, pr_options
          ).and_return([nil].each)

          expect(client).to receive(:each_object).with(
            :milestones, project.import_source, { state: 'all', per_page: '100' }
          )

          expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

          expect(Gitlab::GithubImport::Stage::ImportBaseDataWorker)
            .to receive(:perform_async)
            .with(project.id)

          worker.import(client, project)
        end
      end
    end
  end
end
