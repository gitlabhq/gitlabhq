# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }
  let(:options) { { state: 'all', sort: 'number', direction: 'desc', per_page: '1' } }

  let(:worker) { described_class.new }
  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

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

        expect(import_state)
          .to receive(:refresh_jid_expiration)

        expect(InternalId).to receive(:exists?).and_return(false)

        expect(client).to receive(:each_object).with(
          :pulls, project.import_source, options
        ).and_return([{ number: 4 }].each)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :collaborators)

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

        expect(import_state)
          .to receive(:refresh_jid_expiration)

        expect(InternalId).to receive(:exists?).and_return(false)

        expect(client).to receive(:each_object).with(
          :pulls, project.import_source, options
        ).and_return([nil].each)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :collaborators)

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

        expect(import_state)
          .to receive(:refresh_jid_expiration)

        expect(InternalId).to receive(:exists?).and_return(true)

        expect(client).not_to receive(:each_object)
        expect(MergeRequest).not_to receive(:track_target_project_iid!)

        worker.import(client, project)
      end
    end
  end

  it 'raises an error' do
    exception = StandardError.new('_some_error_')

    expect(client).to receive(:each_object).with(
      :pulls, project.import_source, options
    ).and_return([{ number: 4 }].each)

    expect_next_instance_of(Gitlab::GithubImport::Importer::PullRequestsImporter) do |importer|
      expect(importer).to receive(:execute).and_raise(exception)
    end
    expect(Gitlab::Import::ImportFailureService).to receive(:track)
                                                      .with(
                                                        project_id: project.id,
                                                        exception: exception,
                                                        error_source: described_class.name,
                                                        fail_import: true,
                                                        metrics: true
                                                      ).and_call_original

    expect { worker.import(client, project) }.to raise_error(StandardError)
  end
end
