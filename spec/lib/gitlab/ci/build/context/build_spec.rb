# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:seed_attributes) do
    {
      name: 'some-job',
      tag_list: %w[ruby docker postgresql],
      needs_attributes: [{ name: 'setup-test-env', artifacts: true, optional: false }],
      environment: 'test',
      yaml_variables: [{ key: 'YAML_KEY', value: 'yaml_value' }],
      options: {
        instance: 1,
        parallel: { total: 2 },
        environment: {
          name: 'test',
          url: 'http://example.com',
          deployment_tier: 'testing',
          kubernetes: { namespace: 'k8s_namespace' }
        }
      }
    }
  end

  before_all do
    create(:cluster_agent, project: project)
  end

  subject(:context) { described_class.new(pipeline, seed_attributes) }

  shared_examples 'variables collection' do
    it 'returns a collection of variables' do
      is_expected.to include('CI_COMMIT_REF_NAME'  => 'master')
      is_expected.to include('CI_PIPELINE_IID'     => pipeline.iid.to_s)
      is_expected.to include('CI_PROJECT_PATH'     => project.full_path)
      is_expected.to include('CI_JOB_NAME'         => 'some-job')
      is_expected.to include('YAML_KEY'            => 'yaml_value')
      is_expected.to include('CI_NODE_INDEX'       => '1')
      is_expected.to include('CI_NODE_TOTAL'       => '2')
      is_expected.to include('CI_ENVIRONMENT_NAME' => 'test')
      is_expected.to include('CI_ENVIRONMENT_URL'  => 'http://example.com')
      is_expected.to include('CI_ENVIRONMENT_TIER' => 'testing')
      is_expected.to include('KUBECONFIG'          => anything)
      is_expected.to include('GITLAB_USER_ID'      => user.id.to_s)
      is_expected.to include('GITLAB_USER_EMAIL'   => user.email)
      is_expected.to include('GITLAB_USER_LOGIN'   => user.username)
      is_expected.to include('GITLAB_USER_NAME'    => user.name)
    end

    context 'without passed build-specific attributes' do
      let(:context) { described_class.new(pipeline) }

      it 'returns a collection of variables' do
        is_expected.to include('CI_JOB_NAME'        => nil)
        is_expected.to include('CI_COMMIT_REF_NAME' => 'master')
        is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path)
      end
    end
  end

  describe '#variables' do
    subject(:variables) { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'

    context 'when the pipeline has a trigger request' do
      let!(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline) }

      it 'includes trigger variables' do
        expect(variables).to include('CI_PIPELINE_TRIGGERED' => 'true')
        expect(variables).to include('CI_TRIGGER_SHORT_TOKEN' => trigger_request.trigger_short_token)
      end
    end

    context 'when environment and kubernetes namespace include variables' do
      let(:seed_attributes) do
        {
          name: 'some-job',
          environment: 'env-$CI_COMMIT_REF_NAME',
          options: {
            environment: { name: 'env-$CI_COMMIT_REF_NAME', kubernetes: { namespace: 'k8s-$CI_PROJECT_PATH' } }
          }
        }
      end

      let!(:default_cluster) do
        create(
          :cluster,
          :not_managed,
          platform_type: :kubernetes,
          projects: [project],
          environment_scope: '*',
          platform_kubernetes: default_cluster_kubernetes
        )
      end

      let(:default_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'default-AAA') }

      it 'returns a collection of variables' do
        is_expected.to include('CI_ENVIRONMENT_NAME' => 'env-master')
        is_expected.to include('KUBE_NAMESPACE' => "k8s-#{project.full_path}")
      end
    end

    context 'when environment includes nested variables' do
      let(:seed_attributes) do
        {
          name: 'some-job',
          environment: 'env-$NESTED_VAR',
          yaml_variables: [
            { key: 'NESTED_VAR', value: 'nested-$CI_COMMIT_REF_NAME' }
          ],
          options: {
            environment: { name: 'env-$NESTED_VAR' }
          }
        }
      end

      it 'expands the nested variable' do
        is_expected.to include('CI_ENVIRONMENT_NAME' => 'env-nested-master')
      end
    end

    context 'when kubernetes namespace includes nested variables' do
      let(:seed_attributes) do
        {
          name: 'some-job',
          environment: 'env-master',
          yaml_variables: [
            { key: 'NESTED_VAR', value: 'nested-$CI_PROJECT_PATH' }
          ],
          options: {
            environment: { name: 'env-master', kubernetes: { namespace: 'k8s-$NESTED_VAR' } }
          }
        }
      end

      let!(:default_cluster) do
        create(
          :cluster,
          :not_managed,
          platform_type: :kubernetes,
          projects: [project],
          environment_scope: '*',
          platform_kubernetes: default_cluster_kubernetes
        )
      end

      let(:default_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'default-AAA') }

      it 'does not expand the nested variable' do
        is_expected.to include('KUBE_NAMESPACE' => "k8s-nested-$CI_PROJECT_PATH")
      end
    end
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { expect(context.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash_expanded' do
    subject { context.variables_hash_expanded }

    it { expect(context.variables_hash_expanded).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end
end
