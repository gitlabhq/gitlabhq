# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:options) { { state: 'all', sort: 'number', direction: 'desc', per_page: '1' } }
  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    context 'with pull requests' do
      it 'imports all the pull requests and allocates internal iids' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::PullRequestsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(waiter)

        expect(InternalId).to receive(:exists?).and_return(false)

        expect(client).to receive(:each_object).with(
          :pulls, project.import_source, options
        ).and_return([{ number: 4 }].each)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, 'collaborators')

        expect(MergeRequest).to receive(:track_target_project_iid!)

        worker.import(client, project)
      end
    end

    context 'without pull requests' do
      it 'does not allocate internal iids' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::PullRequestsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(waiter)

        expect(InternalId).to receive(:exists?).and_return(false)

        expect(client).to receive(:each_object).with(
          :pulls, project.import_source, options
        ).and_return([nil].each)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, 'collaborators')

        expect(MergeRequest).not_to receive(:track_target_project_iid!)

        worker.import(client, project)
      end
    end

    context 'when retrying' do
      it 'does not allocate internal iids' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::PullRequestsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(waiter)

        expect(InternalId).to receive(:exists?).and_return(true)

        expect(client).not_to receive(:each_object)
        expect(MergeRequest).not_to receive(:track_target_project_iid!)

        worker.import(client, project)
      end
    end
  end
end
