# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::FinishImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  it 'does not abort on failure' do
    expect(worker.abort_on_failure).to be_falsey
  end

  describe '#perform' do
    it 'finalises the import process' do
      expect_next_instance_of(Gitlab::Import::Metrics, :bitbucket_importer, project) do |metric|
        expect(metric).to receive(:track_finished_import)
      end

      worker.perform(project.id)

      expect(project.import_state.reload).to be_finished
    end
  end
end
