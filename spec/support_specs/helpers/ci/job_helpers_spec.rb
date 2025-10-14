# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobHelpers, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  describe '#stub_ci_job_definition' do
    let(:existing_variables) { [{ key: 'VAR', value: 'existing var' }] }
    let(:existing_options) { { script: 'existing script' } }
    let(:new_options) { { script: 'new script' } }
    let(:new_config) { { options: new_options } }

    let(:job) { build(:ci_build, :interruptible, options: existing_options, yaml_variables: existing_variables) }

    subject(:call_stub) { stub_ci_job_definition(job, **new_config) }

    shared_examples 'stubs the job definition' do
      it 'only changes the value of the new config attribute provided' do
        expect(job.options).to eq(existing_options)
        expect(job.yaml_variables).to eq(existing_variables)
        expect(job.interruptible).to be(true)

        call_stub

        expect(job.options).to eq(new_options)
        expect(job.yaml_variables).to eq(existing_variables)
        expect(job.interruptible).to be(true)
      end
    end

    it_behaves_like 'stubs the job definition'

    context 'when the job is persisted' do
      let(:job) { create(:ci_build, :interruptible, options: existing_options, yaml_variables: existing_variables) }

      it_behaves_like 'stubs the job definition'
    end

    context 'when the job does not have a job definition' do
      let(:job) { build(:ci_build, :without_job_definition) }

      it 'returns the value of the new config attribute provided' do
        call_stub

        expect(job.options).to eq(new_options)
      end
    end

    context 'when an unknown config attribute is provided' do
      let(:new_config) { { options: new_options, unknown_key1: 'unknown1', unknown_key2: 'unknown2' } }

      it 'raises an error' do
        expect { call_stub }.to raise_error(ArgumentError,
          "You can only stub valid job definition config attributes. Invalid key(s): unknown_key1, unknown_key2. " \
            "Allowed: #{Ci::JobDefinition::CONFIG_ATTRIBUTES.join(', ')}")
      end
    end

    context 'when the provided config attribute value has invalid format' do
      let(:new_options) { 'not an object' }

      # TODO: Update this test to expect an ActiveRecord::RecordInvalid error when ci_job_definitions_config.json
      # is updated in https://gitlab.com/gitlab-org/gitlab/-/issues/560157.
      it 'does not raise an error' do
        expect { call_stub }.not_to raise_error
      end
    end
  end
end
