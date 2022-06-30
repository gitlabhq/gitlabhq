# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportIssueEventsWorker do
  subject(:worker) { described_class.new }

  let(:project) { create(:project) }
  let!(:group) { create(:group, projects: [project]) }
  let(:feature_flag_state) { [group] }

  describe '#import' do
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter') }
    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    before do
      stub_feature_flags(github_importer_issue_events_import: feature_flag_state)
    end

    it 'imports all the issue events' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer).to receive(:execute).and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :notes)

      worker.import(client, project)
    end

    context 'when feature flag is disabled' do
      let(:feature_flag_state) { false }

      it 'skips issue events import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter).not_to receive(:new)
        expect(Gitlab::GithubImport::AdvanceStageWorker).to receive(:perform_async).with(project.id, {}, :notes)

        worker.import(client, project)
      end
    end
  end
end
