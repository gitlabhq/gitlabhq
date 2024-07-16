# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build, feature_category: :pipeline_composition do
  let(:pipeline)        { create(:ci_pipeline) }
  let(:seed_attributes) do
    {
      name: 'some-job',
      tag_list: %w[ruby docker postgresql],
      needs_attributes: [{ name: 'setup-test-env', artifacts: true, optional: false }],
      environment: 'test',
      yaml_variables: [{ key: 'YAML_KEY', value: 'yaml_value' }],
      options: { instance: 1, parallel: { total: 2 } }
    }
  end

  subject(:context) { described_class.new(pipeline, seed_attributes) }

  shared_examples 'variables collection' do
    it 'returns a collection of variables' do
      is_expected.to include('CI_COMMIT_REF_NAME'  => 'master')
      is_expected.to include('CI_PIPELINE_IID'     => pipeline.iid.to_s)
      is_expected.to include('CI_PROJECT_PATH'     => pipeline.project.full_path)
      is_expected.to include('CI_JOB_NAME'         => 'some-job')
      is_expected.to include('CI_ENVIRONMENT_NAME' => 'test')
      is_expected.to include('YAML_KEY'            => 'yaml_value')
      is_expected.to include('CI_NODE_INDEX'       => '1')
      is_expected.to include('CI_NODE_TOTAL'       => '2')
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
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'

    context 'when the FF ci_variables_optimization_for_yaml_and_node is disabled' do
      before do
        stub_feature_flags(ci_variables_optimization_for_yaml_and_node: false)
      end

      it_behaves_like 'variables collection'
    end
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { expect(context.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end
end
