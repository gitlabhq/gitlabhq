# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::SetBuildSources, feature_category: :security_policy_management do
  include RepoHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be_with_reload(:compliance_project) { create(:project, :empty_repo, group: group) }
  let_it_be(:user) { create(:user, developer_of: [project, compliance_project]) }

  let(:ref_name) { 'refs/heads/master' }
  let(:opts) { {} }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master'
    )
  end

  let(:pipeline) { build(:ci_pipeline, project: project) }

  subject(:run_chain) do
    [
      Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Seed.new(pipeline, command)
    ].map(&:perform!)
    described_class.new(pipeline, command).perform!
  end

  describe '#perform!' do
    let(:config) do
      {
        production: { stage: 'deploy', script: 'cap prod' },
        rspec: { stage: 'test', script: 'rspec' },
        spinach: { stage: 'test', script: 'spinach' },
        child: { trigger: { include: [{ local: 'child.yml' }] } }
      }
    end

    let(:child_config) do
      {
        child_job: { stage: 'test', script: 'child' }
      }
    end

    around do |example|
      create_and_delete_files(
        project, { '.gitlab-ci.yml' => YAML.dump(config) }
      ) do
        create_and_delete_files(
          project, { 'child.yml' => YAML.dump(child_config) }
        ) do
          pipeline.sha = project.commit.id
          example.run
        end
      end
    end

    it 'sets the build source based on pipeline source' do
      run_chain

      builds = command.pipeline_seed.stages.flat_map(&:statuses)
      expect(builds.size).to eq(4)
      builds.each do |build|
        expect(build.build_source.project_id).to eq(project.id)
        expect(build.build_source.source).to eq('push')
      end
    end
  end
end
