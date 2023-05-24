# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::ImportNotesWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods

  describe '#perform' do
    context 'when the import succeeds' do
      before do
        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::NotesImporter) do |importer|
          allow(importer).to receive(:execute).and_return(Gitlab::JobWaiter.new(2, '123'))
        end
      end

      it 'schedules the next stage' do
        expect(Gitlab::BitbucketServerImport::AdvanceStageWorker).to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :lfs_objects)

        worker.perform(project.id)
      end
    end
  end
end
