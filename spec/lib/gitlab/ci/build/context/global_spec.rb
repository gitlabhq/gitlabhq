# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Global do
  let(:pipeline)       { create(:ci_pipeline) }
  let(:yaml_variables) { {} }

  let(:context) { described_class.new(pipeline, yaml_variables: yaml_variables) }

  describe '#variables' do
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
    it { is_expected.to include('CI_PIPELINE_IID'    => pipeline.iid.to_s) }
    it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }

    it { is_expected.not_to have_key('CI_JOB_NAME') }
    it { is_expected.not_to have_key('CI_BUILD_REF_NAME') }

    context 'with passed yaml variables' do
      let(:yaml_variables) { [{ key: 'SUPPORTED', value: 'parsed', public: true }] }

      it { is_expected.to include('SUPPORTED' => 'parsed') }
    end
  end
end
