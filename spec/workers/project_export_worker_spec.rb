# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportWorker, feature_category: :importers do
  it_behaves_like 'export worker'

  context 'exporters duration measuring' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:user) { create(:user, owner_of: project) }

    let(:jid) { SecureRandom.hex(8) }
    let(:params) { {} }
    let(:worker) { described_class.new }

    before do
      allow(worker).to receive(:jid).and_return(jid)
    end

    subject(:perform) { worker.perform(user.id, project.id, {}, params) }

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

      perform
    end

    it 'creates a ProjectExportJob in the correct state' do
      expect { perform }.to change { ProjectExportJob.count }.by(1)

      expect(project.export_jobs).to contain_exactly(
        have_attributes(
          user: user,
          exported_by_admin: false,
          jid: jid,
          status: 2
        )
      )
    end

    context 'when user was an admin' do
      let(:params) { { exported_by_admin: true } }

      it 'creates a ProjectExportJob in correct state' do
        perform

        expect(project.export_jobs).to contain_exactly(
          have_attributes(
            user: user,
            exported_by_admin: true
          )
        )
      end
    end
  end
end
