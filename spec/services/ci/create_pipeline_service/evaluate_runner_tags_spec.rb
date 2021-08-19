# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  let_it_be(:group)          { create(:group, :private) }
  let_it_be(:group_variable) { create(:ci_group_variable, group: group, key: 'RUNNER_TAG', value: 'group')}
  let_it_be(:project)        { create(:project, :repository, group: group) }
  let_it_be(:user)           { create(:user) }

  let(:service)  { described_class.new(project, user, ref: 'master') }
  let(:pipeline) { service.execute(:push).payload }
  let(:job)      { pipeline.builds.find_by(name: 'job') }

  before do
    project.add_developer(user)
    stub_ci_pipeline_yaml_file config
  end

  context 'when the variable is set' do
    let(:config) do
      <<~EOS
        variables:
          KUBERNETES_RUNNER: kubernetes

        job:
          tags:
            - docker
            - $KUBERNETES_RUNNER
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the evaluated variable' do
      expect(pipeline).to be_created_successfully
      expect(job.tags.pluck(:name)).to match_array(%w[docker kubernetes])
    end
  end

  context 'when the tag is composed by two variables' do
    let(:config) do
      <<~EOS
        variables:
          CLOUD_PROVIDER: aws
          KUBERNETES_RUNNER: kubernetes
          ENVIRONMENT_NAME: prod

        job:
          tags:
            - docker
            - $CLOUD_PROVIDER-$KUBERNETES_RUNNER-$ENVIRONMENT_NAME
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the evaluated variables' do
      expect(pipeline).to be_created_successfully
      expect(job.tags.pluck(:name)).to match_array(%w[docker aws-kubernetes-prod])
    end
  end

  context 'when the variable is not set' do
    let(:config) do
      <<~EOS
        job:
          tags:
            - docker
            - $KUBERNETES_RUNNER
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the variable as a regular string' do
      expect(pipeline).to be_created_successfully
      expect(job.tags.pluck(:name)).to match_array(%w[docker $KUBERNETES_RUNNER])
    end
  end

  context 'when the tag uses group variables' do
    let(:config) do
      <<~EOS
        job:
          tags:
            - docker
            - $RUNNER_TAG
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the evaluated variables' do
      expect(pipeline).to be_created_successfully
      expect(job.tags.pluck(:name)).to match_array(%w[docker group])
    end
  end

  context 'when the tag has the same variable name defined for both group and project' do
    let_it_be(:project_variable) { create(:ci_variable, project: project, key: 'RUNNER_TAG', value: 'project') }

    let(:config) do
      <<~EOS
        variables:
          RUNNER_TAG: pipeline
        job:
          tags:
            - docker
            - $RUNNER_TAG
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the project variable instead of group due to variable precedence' do
      expect(pipeline).to be_created_successfully
      expect(job.tags.pluck(:name)).to match_array(%w[docker project])
    end
  end

  context 'with parallel:matrix config' do
    let(:tags) { pipeline.builds.map(&:tags).flatten.pluck(:name) }

    let(:config) do
      <<~EOS
        job:
          parallel:
            matrix:
              - PROVIDER: [aws, gcp]
                STACK: [monitoring, backup, app]
          tags:
            - ${PROVIDER}-${STACK}
          script:
            - echo "Hello runner selector feature"
      EOS
    end

    it 'uses the evaluated variables' do
      expect(pipeline).to be_created_successfully
      expect(tags).to match_array(%w[aws-monitoring aws-backup aws-app gcp-monitoring gcp-backup gcp-app])
    end
  end
end
