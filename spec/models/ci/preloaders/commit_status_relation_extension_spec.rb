# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Preloaders::CommitStatusRelationExtension, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }
  let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline) }
  let_it_be(:generic_status) { create(:generic_commit_status, pipeline: pipeline) }

  let(:relation) { pipeline.statuses.extending(described_class) }

  it 'preloads associations that only some subclasses define' do
    statuses = relation.preload(:job_artifacts, :job_definition, { project: :route }).to_a

    expect(statuses).to contain_exactly(build, bridge, generic_status)

    loaded_build = statuses.find { |status| status.id == build.id }
    loaded_bridge = statuses.find { |status| status.id == bridge.id }

    expect(loaded_build.association(:job_artifacts)).to be_loaded
    expect(loaded_build.association(:job_definition)).to be_loaded
    expect(loaded_bridge.association(:job_definition)).to be_loaded
    expect(statuses).to all(satisfy { |status| status.association(:project).loaded? })
    expect(statuses.map(&:project).map(&:object_id).uniq).to have_attributes(size: 1)
  end

  it 'splits multi-key hashes so each association is routed on its own' do
    statuses = relation.preload({ project: :route, job_artifacts: :project }).to_a

    expect(statuses.find { |status| status.id == build.id }.association(:job_artifacts)).to be_loaded
    expect(statuses).to all(satisfy { |status| status.project.association(:route).loaded? })
  end

  it 'reuses the project loaded through the pipeline' do
    statuses = nil

    expect { statuses = relation.preload(:project, job_artifacts: :project).to_a }
      .not_to make_queries_matching(/FROM "projects"/)
    expect(statuses.map(&:project)).to all(be(pipeline.project))
    expect(statuses.find { |status| status.id == build.id }.job_artifacts.map(&:project)).to all(be(pipeline.project))
  end

  it 'loads the project when the statuses were not loaded through their pipeline' do
    statuses = CommitStatus.where(commit_id: pipeline.id, partition_id: pipeline.partition_id)
      .extending(described_class).preload(:project).to_a

    expect(statuses).to all(satisfy { |status| status.association(:project).loaded? })
    expect(statuses.map(&:project)).to all(eq(pipeline.project))
  end

  it 'marks preloaded records strict when the relation is strict loading' do
    statuses = relation.strict_loading.preload(:project).to_a

    expect(statuses.first.project).to be_strict_loading
  end

  it 'leaves includes to the join when the relation eager loads' do
    statuses = relation.eager_load(:pipeline).preload(:job_artifacts).to_a

    expect(statuses).to all(satisfy { |status| status.association(:pipeline).loaded? })
    expect(statuses.find { |status| status.id == build.id }.association(:job_artifacts)).to be_loaded
  end

  it 'treats includes like preload' do
    statuses = relation.includes(:job_artifacts).to_a

    expect(statuses.find { |status| status.id == build.id }.association(:job_artifacts)).to be_loaded
  end

  it 'raises for association names no commit status class defines' do
    expect { relation.preload(:job_definitions).to_a }
      .to raise_error(ArgumentError, /Unknown associations for CommitStatus preload: \[:job_definitions\]/)
  end

  it 'does not query per record for the preloaded associations' do
    statuses = relation.preload(:job_artifacts).to_a

    expect { statuses.each { |status| status.try(:job_artifacts)&.to_a } }.not_to exceed_query_limit(0)
  end
end
