require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateStageStatus, :migration, schema: 20170711145320 do
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:jobs) { table(:ci_builds) }

  STATUSES = { created: 0, pending: 1, running: 2, success: 3,
               failed: 4, canceled: 5, skipped: 6, manual: 7 }.freeze

  before do
    projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1')
    pipelines.create!(id: 1, project_id: 1, ref: 'master', sha: 'adf43c3a')
    stages.create!(id: 1, pipeline_id: 1, project_id: 1, name: 'test', status: nil)
    stages.create!(id: 2, pipeline_id: 1, project_id: 1, name: 'deploy', status: nil)
  end

  context 'when stage status is known' do
    before do
      create_job(project: 1, pipeline: 1, stage: 'test', status: 'success')
      create_job(project: 1, pipeline: 1, stage: 'test', status: 'running')
      create_job(project: 1, pipeline: 1, stage: 'deploy', status: 'failed')
    end

    it 'sets a correct stage status' do
      described_class.new.perform(1, 2)

      expect(stages.first.status).to eq STATUSES[:running]
      expect(stages.second.status).to eq STATUSES[:failed]
    end
  end

  context 'when stage status is not known' do
    it 'sets a skipped stage status' do
      described_class.new.perform(1, 2)

      expect(stages.first.status).to eq STATUSES[:skipped]
      expect(stages.second.status).to eq STATUSES[:skipped]
    end
  end

  context 'when stage status includes status of a retried job' do
    before do
      create_job(project: 1, pipeline: 1, stage: 'test', status: 'canceled')
      create_job(project: 1, pipeline: 1, stage: 'deploy', status: 'failed', retried: true)
      create_job(project: 1, pipeline: 1, stage: 'deploy', status: 'success')
    end

    it 'sets a correct stage status' do
      described_class.new.perform(1, 2)

      expect(stages.first.status).to eq STATUSES[:canceled]
      expect(stages.second.status).to eq STATUSES[:success]
    end
  end

  context 'when some job in the stage is blocked / manual' do
    before do
      create_job(project: 1, pipeline: 1, stage: 'test', status: 'failed')
      create_job(project: 1, pipeline: 1, stage: 'test', status: 'manual')
      create_job(project: 1, pipeline: 1, stage: 'deploy', status: 'success', when: 'manual')
    end

    it 'sets a correct stage status' do
      described_class.new.perform(1, 2)

      expect(stages.first.status).to eq STATUSES[:manual]
      expect(stages.second.status).to eq STATUSES[:success]
    end
  end

  def create_job(project:, pipeline:, stage:, status:, **opts)
    stages = { test: 1, build: 2, deploy: 3 }

    jobs.create!(project_id: project, commit_id: pipeline,
                 stage_idx: stages[stage.to_sym], stage: stage,
                 status: status, **opts)
  end
end
