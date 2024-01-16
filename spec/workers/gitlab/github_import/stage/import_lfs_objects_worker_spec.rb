# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportLfsObjectsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports all the lfs objects' do
      importer = instance_double(Gitlab::GithubImport::Importer::LfsObjectsImporter)
      client = instance_double(Gitlab::GithubImport::Client)
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::LfsObjectsImporter)
        .to receive(:new)
        .with(project, nil)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, 'finish')

      worker.import(client, project)
    end
  end
end
