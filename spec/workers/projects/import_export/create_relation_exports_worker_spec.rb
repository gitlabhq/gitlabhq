# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::CreateRelationExportsWorker, feature_category: :importers do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:after_export_strategy) { {} }
  let(:params) { {} }
  let(:jid) { SecureRandom.hex(8) }
  let(:job_args) { [user.id, project.id, after_export_strategy, params] }

  before do
    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid).and_return(jid)
    end
  end

  it_behaves_like 'an idempotent worker'

  subject(:perform) {  described_class.new.perform(user.id, project.id, after_export_strategy, params) }

  context 'when job is re-enqueued after an interuption and same JID is used' do
    before do
      allow_next_instance_of(described_class) do |job|
        allow(job).to receive(:jid).and_return(1234)
      end
    end

    it_behaves_like 'an idempotent worker'

    it 'does not start the export process twice' do
      project.export_jobs.create!(jid: 1234, status_event: :start)

      expect { perform }.not_to change { Projects::ImportExport::WaitRelationExportsWorker.jobs.size }
    end
  end

  it 'creates a export_job and sets the status to `started`' do
    perform

    export_job = project.export_jobs.last
    expect(export_job.started?).to eq(true)
  end

  it 'creates relation export records and enqueues a worker for each relation to be exported' do
    allow(Projects::ImportExport::RelationExport).to receive(:relation_names_list).and_return(%w[relation_1 relation_2])

    expect { perform }.to change { Projects::ImportExport::RelationExportWorker.jobs.size }.by(2)

    relation_exports = project.export_jobs.last.relation_exports
    expect(relation_exports.collect(&:relation)).to match_array(%w[relation_1 relation_2])
  end

  it 'enqueues a WaitRelationExportsWorker' do
    allow(Projects::ImportExport::WaitRelationExportsWorker).to receive(:perform_in)

    perform

    export_job = project.export_jobs.last
    expect(Projects::ImportExport::WaitRelationExportsWorker).to have_received(:perform_in).with(
      described_class::INITIAL_DELAY,
      export_job.id,
      user.id,
      after_export_strategy
    )
  end

  it 'creates a ProjectExportJob in the correct state' do
    expect { perform }.to change { ProjectExportJob.count }.by(1)

    expect(project.export_jobs).to contain_exactly(
      have_attributes(
        user: user,
        exported_by_admin: false,
        jid: jid,
        status: 1
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
