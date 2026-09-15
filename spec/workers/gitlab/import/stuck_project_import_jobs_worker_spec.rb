# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::StuckProjectImportJobsWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe 'with scheduled import_status' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:project, :import_scheduled).import_state }

      before do
        import_state.update!(jid: '123')
      end
    end
  end

  describe 'with started import_status' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:project, :import_started).import_state }

      before do
        import_state.update!(jid: '123')
      end
    end
  end

  describe 'flagging the import as timed out (not just failed)' do
    let(:import_state) { create(:project, :import_started, import_type: 'github').import_state }

    before do
      import_state.update!(jid: '123')
      allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([import_state.jid])
    end

    it 'tracks the timeout_project_import event, not fail_project_import, and persists as failed' do
      project = import_state.project

      expect { worker.perform }
        .to trigger_internal_events('timeout_project_import')
        .with(
          category: 'ProjectImportState',
          project: project,
          user: project.creator,
          namespace: project.namespace,
          additional_properties: { label: 'github' }
        )
        .and not_trigger_internal_events('fail_project_import')

      expect(import_state.reload.status).to eq('failed')
    end
  end
end
