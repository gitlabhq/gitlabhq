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
        expect(build.job_source.project_id).to eq(project.id)
        expect(build.job_source.source).to eq('push')
      end
    end

    # The CE base class defines security_scan_profile_build? as a stub
    # returning false, overridden in EE via prepend_mod_with. Since EE is
    # always loaded in the EE test suite, the CE method is unreachable
    # through perform!. We invoke it directly to verify and cover the stub.
    it 'returns false for security_scan_profile_build? in CE' do
      step = described_class.new(pipeline, command)
      build = instance_double(::Ci::Build, name: 'test')
      method = described_class.instance_method(:security_scan_profile_build?)
      ce_method = method.super_method || method

      expect(ce_method.bind_call(step, build)).to be false
    end
  end
end
