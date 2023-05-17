# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportWorker, feature_category: :importers do
  it_behaves_like 'export worker'

  context 'exporters duration measuring' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:worker) { described_class.new }

    subject { worker.perform(user.id, project.id) }

    before do
      project.add_owner(user)
    end

    it 'logs exporters execution duration' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:version_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:avatar_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:tree_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:uploads_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:repo_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:wiki_repo_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:lfs_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:snippets_repo_saver_duration_s, anything)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:design_repo_saver_duration_s, anything)

      subject
    end
  end
end
