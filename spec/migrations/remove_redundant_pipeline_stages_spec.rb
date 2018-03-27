require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180119121225_remove_redundant_pipeline_stages.rb')

describe RemoveRedundantPipelineStages, :migration do
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:builds) { table(:ci_builds) }

  before do
    projects.create!(id: 123, name: 'gitlab', path: 'gitlab-ce')
    pipelines.create!(id: 234, project_id: 123, ref: 'master', sha: 'adf43c3a')

    stages.create!(id: 6, project_id: 123, pipeline_id: 234, name: 'build')
    stages.create!(id: 10, project_id: 123, pipeline_id: 234, name: 'build')
    stages.create!(id: 21, project_id: 123, pipeline_id: 234, name: 'build')
    stages.create!(id: 41, project_id: 123, pipeline_id: 234, name: 'test')
    stages.create!(id: 62, project_id: 123, pipeline_id: 234, name: 'test')
    stages.create!(id: 102, project_id: 123, pipeline_id: 234, name: 'deploy')

    builds.create!(id: 1, commit_id: 234, project_id: 123, stage_id: 10)
    builds.create!(id: 2, commit_id: 234, project_id: 123, stage_id: 21)
    builds.create!(id: 3, commit_id: 234, project_id: 123, stage_id: 21)
    builds.create!(id: 4, commit_id: 234, project_id: 123, stage_id: 41)
    builds.create!(id: 5, commit_id: 234, project_id: 123, stage_id: 62)
    builds.create!(id: 6, commit_id: 234, project_id: 123, stage_id: 102)
  end

  it 'removes ambiguous stages and preserves builds' do
    expect(stages.all.count).to eq 6
    expect(builds.all.count).to eq 6

    migrate!

    expect(stages.all.count).to eq 1
    expect(builds.all.count).to eq 6
    expect(builds.all.pluck(:stage_id).compact).to eq [102]
  end

  it 'retries when incorrectly added index exception is caught' do
    allow_any_instance_of(described_class)
      .to receive(:remove_redundant_pipeline_stages!)

    expect_any_instance_of(described_class)
      .to receive(:remove_outdated_index!)
      .exactly(100).times.and_call_original

    expect { migrate! }
      .to raise_error StandardError, /Failed to add an unique index/
  end

  it 'does not retry when unknown exception is being raised' do
    allow(subject).to receive(:remove_outdated_index!)
    expect(subject).to receive(:remove_redundant_pipeline_stages!).once
    allow(subject).to receive(:add_unique_index!).and_raise(StandardError)

    expect { subject.up(attempts: 3) }.to raise_error StandardError
  end
end
