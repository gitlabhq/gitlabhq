# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportProtectedBranchesWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:importer) { instance_double('Gitlab::GithubImport::Importer::ProtectedBranchImporter') }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports all the pull requests' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::ProtectedBranchesImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, 'lfs_objects')

      worker.import(client, project)
    end
  end
end
