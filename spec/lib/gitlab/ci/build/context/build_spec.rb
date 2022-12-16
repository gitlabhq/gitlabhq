# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build, feature_category: :pipeline_authoring do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:job) { build(:ci_build, pipeline: pipeline, name: 'some-job') }

  subject(:context) { described_class.new(pipeline, job) }

  shared_examples 'variables collection' do
    it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
    it { is_expected.to include('CI_PIPELINE_IID'    => pipeline.iid.to_s) }
    it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }
    it { is_expected.to include('CI_JOB_NAME'        => 'some-job') }
    it { is_expected.to include('CI_BUILD_REF_NAME'  => 'master') }

    context 'when environment:name is provided' do
      before do
        job.environment = 'test'
      end

      it { is_expected.to include('CI_ENVIRONMENT_NAME' => 'test') }
    end
  end

  describe '#variables' do
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { expect(context.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end
end
