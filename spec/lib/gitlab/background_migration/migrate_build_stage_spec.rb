require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateBuildStage, :migration, schema: 20180212101928 do
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:jobs) { table(:ci_builds) }

  STATUSES = { created: 0, pending: 1, running: 2, success: 3,
               failed: 4, canceled: 5, skipped: 6, manual: 7 }.freeze

  before do
    projects.create!(id: 123, name: 'gitlab', path: 'gitlab-ce')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')

    jobs.create!(id: 1, commit_id: 1, project_id: 123,
                 stage_idx: 2, stage: 'build', status: :success)
    jobs.create!(id: 2, commit_id: 1, project_id: 123,
                 stage_idx: 2, stage: 'build', status: :success)
    jobs.create!(id: 3, commit_id: 1, project_id: 123,
                 stage_idx: 1, stage: 'test', status: :failed)
    jobs.create!(id: 4, commit_id: 1, project_id: 123,
                 stage_idx: 1, stage: 'test', status: :success)
    jobs.create!(id: 5, commit_id: 1, project_id: 123,
                 stage_idx: 3, stage: 'deploy', status: :pending)
    jobs.create!(id: 6, commit_id: 1, project_id: 123,
                 stage_idx: 3, stage: nil, status: :pending)
  end

  it 'correctly migrates builds stages' do
    expect(stages.count).to be_zero

    described_class.new.perform(1, 6)

    expect(stages.count).to eq 3
    expect(stages.all.pluck(:name)).to match_array %w[test build deploy]
    expect(jobs.where(stage_id: nil)).to be_one
    expect(jobs.find_by(stage_id: nil).id).to eq 6
    expect(stages.all.pluck(:status)).to match_array [STATUSES[:success],
                                                      STATUSES[:failed],
                                                      STATUSES[:pending]]
  end

  it 'recovers from unique constraint violation only twice' do
    allow(described_class::Migratable::Stage)
      .to receive(:find_by).and_return(nil)

    expect(described_class::Migratable::Stage)
      .to receive(:find_by).exactly(3).times

    expect { described_class.new.perform(1, 6) }
      .to raise_error ActiveRecord::RecordNotUnique
  end

  context 'when invalid class can be loaded due to single table inheritance' do
    let(:commit_status) do
      jobs.create!(id: 7, commit_id: 1, project_id: 123, stage_idx: 4,
                   stage: 'post-deploy', status: :failed)
    end

    before do
      commit_status.update_column(:type, 'SomeClass')
    end

    it 'does ignore single table inheritance type' do
      expect { described_class.new.perform(1, 7) }.not_to raise_error
      expect(jobs.find(7)).to have_attributes(stage_id: (a_value > 0))
    end
  end
end
