# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::FinishImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods

  describe '#perform' do
    it 'finalises the import process' do
      expect_next_instance_of(Gitlab::Import::Metrics, :bitbucket_server_importer, project) do |metric|
        expect(metric).to receive(:track_finished_import)
      end

      worker.perform(project.id)

      expect(project.import_state.reload).to be_finished
    end
  end
end
