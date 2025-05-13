# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::EnqueueJobService, '#execute', feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project, created_at: 1.day.ago) }
  let_it_be_with_reload(:build) { create(:ci_build, :manual, pipeline: pipeline) }

  let(:service) do
    described_class.new(build, current_user: user)
  end

  subject(:execute) { service.execute }

  it 'assigns the user to the job' do
    expect { execute }.to change { build.reload.user }.to(user)
  end

  it 'calls enqueue!' do
    expect(build).to receive(:enqueue!)
    execute
  end

  it 'calls Ci::ResetSkippedJobsService' do
    expect_next_instance_of(Ci::ResetSkippedJobsService) do |service|
      expect(service).to receive(:execute).with(build)
    end

    execute
  end

  it 'returns a service response with a job payload' do
    expect(execute).to eq(build)
  end

  context 'when variables are supplied' do
    let(:job_variables) do
      [{ key: 'first', secret_value: 'first' },
        { key: 'second', secret_value: 'second' }]
    end

    let(:service) do
      described_class.new(build, current_user: user, variables: job_variables)
    end

    it 'assigns the variables to the job' do
      execute
      expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
    end
  end

  context 'when the job transition is invalid' do
    let(:bridge) { create(:ci_bridge, :failed, pipeline: pipeline, project: project) }

    let(:service) do
      described_class.new(bridge, current_user: user)
    end

    it 'raises StateMachines::InvalidTransition' do
      expect { execute }.to raise_error StateMachines::InvalidTransition
    end
  end

  context 'when the job is manually triggered another user' do
    let(:job_variables) do
      [{ key: 'third', secret_value: 'third' },
        { key: 'fourth', secret_value: 'fourth' }]
    end

    let(:service) do
      described_class.new(build, current_user: user, variables: job_variables)
    end

    it 'assigns the user and variables to the job', :aggregate_failures do
      service.execute

      build.reload

      expect(build.user).to eq(user)
      expect(build.job_variables.map(&:key)).to contain_exactly('third', 'fourth')
    end
  end
end
