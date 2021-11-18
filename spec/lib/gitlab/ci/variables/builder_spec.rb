# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder do
  let(:builder) { described_class.new(pipeline) }
  let(:pipeline) { create(:ci_pipeline) }
  let(:job) { create(:ci_build, pipeline: pipeline) }

  describe '#scoped_variables' do
    let(:environment) { job.expanded_environment_name }
    let(:dependencies) { true }

    subject { builder.scoped_variables(job, environment: environment, dependencies: dependencies) }

    it 'returns the expected variables' do
      keys = %w[CI_JOB_NAME
                CI_JOB_STAGE
                CI_NODE_TOTAL
                CI_BUILD_NAME
                CI_BUILD_STAGE]

      subject.map { |env| env[:key] }.tap do |names|
        expect(names).to include(*keys)
      end
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(ci_predefined_vars_in_builder: false)
      end

      it 'returns no variables' do
        expect(subject.map { |env| env[:key] }).to be_empty
      end
    end
  end
end
