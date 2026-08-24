# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRouter::JobResponse, feature_category: :continuous_integration do
  let(:runner) { build(:ci_runner, tag_list: %w[docker linux gpu]) }
  let(:job) { build(:ci_build, runner: runner, tag_list: %w[docker linux]) }
  let(:presented_job) { Ci::BuildRunnerPresenter.new(job) }
  let(:public_payload) { ::API::Entities::Ci::JobRequest::Response.new(presented_job).as_json }

  subject(:payload) { described_class.new(presented_job).as_json }

  it 'exposes the tags the job asked for' do
    expect(payload[:job_info][:tags]).to match_array(%w[docker linux])
  end

  it 'exposes the tags the assigned runner offers' do
    expect(payload[:runner_info][:tags]).to match_array(%w[docker linux gpu])
  end

  it 'adds the tags as the only change to the inherited exposures', :aggregate_failures do
    expect(payload[:job_info].keys).to match_array(public_payload[:job_info].keys + [:tags])
    expect(payload[:runner_info].keys).to match_array(public_payload[:runner_info].keys + [:tags])
  end

  it 'leaves the public runner job response untouched', :aggregate_failures do
    expect(public_payload[:job_info]).not_to include(:tags)
    expect(public_payload[:runner_info]).not_to include(:tags)
  end

  context 'when the job and the runner are untagged' do
    let(:runner) { build(:ci_runner) }
    let(:job) { build(:ci_build, runner: runner) }

    it 'exposes empty tag lists rather than omitting them', :aggregate_failures do
      expect(payload[:job_info][:tags]).to eq([])
      expect(payload[:runner_info][:tags]).to eq([])
    end
  end
end
