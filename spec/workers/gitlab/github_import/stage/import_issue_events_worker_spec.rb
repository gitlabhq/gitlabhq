# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportIssueEventsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let!(:group) { create(:group, projects: [project]) }
  let(:settings) { ::Gitlab::GithubImport::Settings.new(project.reload) }
  let(:stage_enabled) { true }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter') }
    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    it 'imports issue events' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer).to receive(:execute).and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, 'attachments')

      worker.import(client, project)
    end
  end
end
