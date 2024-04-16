# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportLfsObjectsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  before do
    allow_next_instance_of(Gitlab::BitbucketImport::Importers::LfsObjectsImporter) do |importer|
      allow(importer).to receive(:execute).and_return(Gitlab::JobWaiter.new(2, '123'))
    end
  end

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  describe '#perform' do
    context 'when the import succeeds' do
      it 'schedules the next stage' do
        expect(Gitlab::BitbucketImport::AdvanceStageWorker).to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :finish)

        worker.perform(project.id)
      end
    end
  end
end
