# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Stage::ImportIssuesWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketImport::StageMethods

  describe '#perform' do
    it 'advances directly to the LFS objects stage without waiting on any jobs' do
      expect(Gitlab::BitbucketImport::AdvanceStageWorker).to receive(:perform_async)
        .with(project.id, {}, :lfs_objects)

      worker.perform(project.id)
    end

    it 'does not advance when the import is no longer started' do
      project = create(:project, :import_canceled)

      expect(Gitlab::BitbucketImport::AdvanceStageWorker).not_to receive(:perform_async)

      worker.perform(project.id)
    end
  end
end
