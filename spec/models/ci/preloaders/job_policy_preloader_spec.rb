# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Preloaders::JobPolicyPreloader, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.sha) }
  let_it_be(:environment) { create(:environment, project: project, name: 'production') }
  let_it_be(:deploy_build) do
    create(:ci_build, :running, :deploy_job, :with_deployment, pipeline: pipeline, environment: environment.name)
  end

  let_it_be(:deploy_bridge) do
    create(:ci_bridge, :running, :deploy_job, :with_deployment, pipeline: pipeline, environment: environment.name)
  end

  let_it_be(:stop_build) do
    create(:ci_build, :with_deployment, pipeline: pipeline, environment: environment.name,
      options: { environment: { name: environment.name, action: 'stop' } })
  end

  let_it_be(:plain_build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:generic_status) { create(:generic_commit_status, pipeline: pipeline) }

  let(:jobs) { pipeline.statuses.reload.to_a } # let_it_be shares the pipeline instance across examples
  let(:deploy_jobs) { jobs.select { |job| job.id.in?([deploy_build.id, deploy_bridge.id]) } }

  def loaded(job)
    jobs.find { |loaded_job| loaded_job.id == job.id }
  end

  subject(:execute) { described_class.new(jobs, user).execute }

  it 'loads the associations the deployable policy reads for builds and bridges' do
    execute

    expect(deploy_jobs.size).to eq(2)
    deploy_jobs.each do |job|
      expect(job.association(:job_environment)).to be_loaded
      expect(job.association(:deployment)).to be_loaded
      expect(job.deployment.environment.association(:last_deployment)).to be_loaded
      expect(job.job_environment.environment).to equal(job.deployment.environment)
      expect(job.persisted_environment).to equal(job.deployment.environment)
      expect(job.persisted_environment.association(:project)).to be_loaded
    end
  end

  it 'points every job at the pipeline project already in memory' do
    expect { execute }.not_to make_queries_matching(/FROM "projects"/)

    expect(jobs.map(&:project)).to all(equal(pipeline.project))
  end

  context 'when the jobs were not loaded through the pipeline' do
    let(:jobs) { CommitStatus.where(commit_id: pipeline.id).to_a }

    it 'loads one project instance for all jobs' do
      execute

      expect(jobs).to all(satisfy { |job| job.association(:project).loaded? })
      expect(jobs.map(&:project).uniq(&:object_id)).to have_attributes(size: 1)
    end
  end

  it 'shares one environment instance across builds and bridges' do
    execute

    expect(loaded(deploy_build).deployment.environment).to equal(loaded(deploy_bridge).deployment.environment)
    expect(execute).to contain_exactly(environment)
  end

  it 'assigns persisted_environment to environment jobs without a deployment' do
    execute

    stop = loaded(stop_build)
    expect(stop.deployment).to be_nil
    expect(stop.persisted_environment).to equal(stop.job_environment.environment)
  end

  it 'replaces an already memoized persisted_environment' do
    job = loaded(deploy_build)
    job.persisted_environment # memoizes a per-job lookup

    execute

    expect(job.persisted_environment).to equal(job.deployment.environment)
  end

  it 'lets the outdated-deployment check run without further queries' do
    execute

    expect { deploy_jobs.each { |job| job.deployment.older_than_last_successful_deployment? } }
      .not_to exceed_query_limit(0)
  end

  it 'tolerates jobs without environments' do
    expect { described_class.new([plain_build, generic_status], user).execute }.not_to raise_error
  end

  it 'tolerates pages without processables' do
    expect(described_class.new([generic_status], user).execute).to eq([])
  end

  it 'tolerates an empty page' do
    expect { expect(described_class.new([], user).execute).to eq([]) }.not_to exceed_query_limit(0)
  end

  context 'with a deployment that has no job_environment row' do
    let_it_be(:legacy_build) { create(:ci_build, :deploy_job, pipeline: pipeline, environment: environment.name) }

    before_all do
      create(:deployment, deployable: legacy_build, environment: environment)
    end

    it 'assigns persisted_environment from the deployment' do
      execute

      build = loaded(legacy_build)
      expect(build.job_environment).to be_nil
      expect(build.persisted_environment).to equal(build.deployment.environment)
    end
  end

  it 'can run again on already preloaded jobs' do
    execute

    expect(described_class.new(jobs, user).execute).to contain_exactly(environment)
    expect(loaded(deploy_build).persisted_environment).to equal(loaded(deploy_build).deployment.environment)
  end

  context 'with bridges to other projects' do
    let_it_be(:downstream_project) { create(:project, :public) }
    let_it_be(:downstream_pipeline) { create(:ci_pipeline, project: downstream_project) }
    let_it_be(:bridge) { create(:ci_bridge, :success, pipeline: pipeline) }
    let_it_be(:manual_project) { create(:project, :public) }
    let_it_be(:manual_bridge) do
      create(:ci_bridge, :manual, pipeline: pipeline, options: { trigger: { project: manual_project.full_path } })
    end

    let_it_be(:played_bridge) do
      create(:ci_bridge, :success, pipeline: pipeline, when: 'manual',
        options: { trigger: { project: manual_project.full_path } })
    end

    let_it_be(:variable_path_bridge) do
      create(:ci_bridge, :manual, pipeline: pipeline, options: { trigger: { project: '$GROUP/project' } })
    end

    before_all do
      create(:ci_sources_pipeline, source_job: bridge, pipeline: downstream_pipeline)
    end

    it 'preloads the downstream project and the access level the pipeline policy reads' do
      execute

      expect(loaded(bridge).association(:downstream_pipeline)).to be_loaded
      expect(loaded(bridge).downstream_pipeline.project.association(:group)).to be_loaded
      expect(user.max_member_access_for_project_ids([downstream_project.id, manual_project.id]))
        .to eq(downstream_project.id => Gitlab::Access::NO_ACCESS, manual_project.id => Gitlab::Access::NO_ACCESS)
    end

    it 'resolves the downstream project of a manual bridge without a query per bridge' do
      execute

      expect { expect(loaded(manual_bridge).downstream_project).to eq(manual_project) }.not_to exceed_query_limit(0)
    end

    it 'does not expand trigger paths of bridges that cannot be played' do
      execute

      expect(loaded(played_bridge).strong_memoized?(:downstream_project_path)).to be(false)
    end

    it 'leaves trigger paths with variable references to the per-bridge lookup' do
      execute

      bridge = loaded(variable_path_bridge)
      expect(bridge.strong_memoized?(:downstream_project_path)).to be(false)
      expect(bridge.strong_memoized?(:downstream_project)).to be(false)
    end

    it 'preloads the stage the bridge variables read' do
      execute

      expect(loaded(bridge).association(:ci_stage)).to be_loaded
    end
  end
end
