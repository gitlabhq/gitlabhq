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

  let(:logger) { instance_double(Gitlab::Ci::Pipeline::Logger, instrument: nil) }

  before_all do
    create(:cluster_agent, project: project)
  end

  before do
    allow(logger).to receive(:instrument).and_yield
  end

  subject(:context) { described_class.new(pipeline, seed_attributes, logger: logger) }

  shared_examples 'variables collection' do
    it 'returns a collection of variables' do
      expect(subject.fetch('CI_COMMIT_REF_NAME')).to eq('main')
      expect(subject.fetch('CI_PIPELINE_IID')).to eq(pipeline.iid.to_s)
      expect(subject.fetch('CI_PROJECT_PATH')).to eq(project.full_path)
      expect(subject.fetch('CI_JOB_NAME')).to eq('some-job')
      expect(subject.fetch('CI_JOB_GROUP_NAME')).to eq('some-job')
      expect(subject.fetch('YAML_KEY')).to eq('yaml_value')
      expect(subject.fetch('CI_NODE_INDEX')).to eq('1')
      expect(subject.fetch('CI_NODE_TOTAL')).to eq('2')
      expect(subject.fetch('CI_ENVIRONMENT_NAME')).to eq('test')
      expect(subject.fetch('CI_ENVIRONMENT_URL')).to eq('http://example.com')
      expect(subject.fetch('CI_ENVIRONMENT_TIER')).to eq('testing')
      expect(subject.fetch('KUBECONFIG')).to be_present
      expect(subject.fetch('GITLAB_USER_ID')).to eq(user.id.to_s)
      expect(subject.fetch('GITLAB_USER_EMAIL')).to eq(user.email)
      expect(subject.fetch('GITLAB_USER_LOGIN')).to eq(user.username)
      expect(subject.fetch('GITLAB_USER_NAME')).to eq(user.name)
    end

    context 'without passed build-specific attributes' do
      let(:context) { described_class.new(pipeline, {}, logger: logger) }

      it 'returns a collection of variables' do
        expect(subject.fetch('CI_JOB_NAME')).to be_nil
        expect(subject.fetch('CI_COMMIT_REF_NAME')).to eq('main')
        expect(subject.fetch('CI_PROJECT_PATH')).to eq(pipeline.project.full_path)
      end
    end
  end

  describe '#variables' do
    subject(:variables) { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it 'instruments with logger' do
      logger = instance_double(Gitlab::Ci::Pipeline::Logger)
      context_with_logger = described_class.new(pipeline, seed_attributes, logger: logger)

      expect(logger).to receive(:instrument).with(:pipeline_seed_context_build_variables).and_yield

      context_with_logger.variables
    end

    it_behaves_like 'variables collection'

    context 'when the pipeline has a trigger request' do
      let!(:trigger) { create(:ci_trigger, project: project) }
      let(:pipeline) { create(:ci_pipeline, trigger: trigger, project: project, user: user) }

      it 'includes trigger variables' do
        expect(variables).to include('CI_PIPELINE_TRIGGERED' => 'true')
        expect(variables).to include('CI_TRIGGER_SHORT_TOKEN' => trigger.trigger_short_token)
      end
    end

    context 'when job is an instance of parallel:matrix' do
      let(:seed_attributes) do
        {
          name: 'some-job: [ruby, ubuntu]',
          options: {
            instance: 1,
            parallel: { total: 2 }
          }
        }
      end

      it 'returns a collection of variables' do
        is_expected.to include('CI_JOB_NAME' => 'some-job: [ruby, ubuntu]')
        is_expected.to include('CI_JOB_GROUP_NAME' => 'some-job')
        is_expected.to include('CI_NODE_INDEX' => '1')
        is_expected.to include('CI_NODE_TOTAL' => '2')
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
        is_expected.to include('CI_ENVIRONMENT_NAME' => 'env-main')
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
        is_expected.to include('CI_ENVIRONMENT_NAME' => 'env-nested-main')
      end
    end

    context 'when kubernetes namespace includes nested variables' do
      let(:seed_attributes) do
        {
          name: 'some-job',
          environment: 'env-main',
          yaml_variables: [
            { key: 'NESTED_VAR', value: 'nested-$CI_PROJECT_PATH' }
          ],
          options: {
            environment: { name: 'env-main', kubernetes: { namespace: 'k8s-$NESTED_VAR' } }
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

    it { expect(context.variables_hash).to be_instance_of(Gitlab::Ci::Variables::Collection::LazyHash) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash_expanded' do
    subject { context.variables_hash_expanded }

    it { expect(context.variables_hash_expanded).to be_instance_of(Gitlab::Ci::Variables::Collection::LazyHash) }

    it_behaves_like 'variables collection'
  end
end
