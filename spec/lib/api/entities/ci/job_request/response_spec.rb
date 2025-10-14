# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRequest::Response, feature_category: :continuous_integration do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:job) do
    create(
      :ci_build, runner: runner,
      options: { inputs: { test_input: { input_type: 'string', default: 'test' } } }
    )
  end

  let(:presented_job) { Ci::BuildRunnerPresenter.new(job) }

  subject(:runner_payload) { described_class.new(presented_job).as_json }

  it 'includes the job inputs' do
    expect(runner_payload[:inputs]).to contain_exactly(
      { key: :test_input, value: { type: 'string', content: 'test' } }
    )
  end
end
