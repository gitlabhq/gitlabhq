# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::CreateRelationExportsWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:after_export_strategy) { {} }
  let(:job_args) { [user.id, project.id, after_export_strategy] }

  before do
    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid) { SecureRandom.hex(8) }
    end
  end

  it_behaves_like 'an idempotent worker'

  context 'when job is re-enqueued after an interuption and same JID is used' do
    before do
      allow_next_instance_of(described_class) do |job|
        allow(job).to receive(:jid).and_return(1234)
      end
    end

    it_behaves_like 'an idempotent worker'

    it 'does not start the export process twice' do
      project.export_jobs.create!(jid: 1234, status_event: :start)

      expect { described_class.new.perform(user.id, project.id, after_export_strategy) }
        .to change { Projects::ImportExport::WaitRelationExportsWorker.jobs.size }.by(0)
    end
  end

  it 'creates a export_job and sets the status to `started`' do
    described_class.new.perform(user.id, project.id, after_export_strategy)

    export_job = project.export_jobs.last
    expect(export_job.started?).to eq(true)
  end

  it 'creates relation export records and enqueues a worker for each relation to be exported' do
    allow(Projects::ImportExport::RelationExport).to receive(:relation_names_list).and_return(%w[relation_1 relation_2])

    expect { described_class.new.perform(user.id, project.id, after_export_strategy) }
      .to change { Projects::ImportExport::RelationExportWorker.jobs.size }.by(2)

    relation_exports = project.export_jobs.last.relation_exports
    expect(relation_exports.collect(&:relation)).to match_array(%w[relation_1 relation_2])
  end

  it 'enqueues a WaitRelationExportsWorker' do
    allow(Projects::ImportExport::WaitRelationExportsWorker).to receive(:perform_in)

    described_class.new.perform(user.id, project.id, after_export_strategy)

    export_job = project.export_jobs.last
    expect(Projects::ImportExport::WaitRelationExportsWorker).to have_received(:perform_in).with(
      described_class::INITIAL_DELAY,
      export_job.id,
      user.id,
      after_export_strategy
    )
  end
end
