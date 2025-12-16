# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropTimedOutService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition) }
  let!(:runner) { create :ci_runner }
  let!(:running_build) { create(:ci_running_build, runner: runner, build: job, created_at: created_at) }
  let(:job) { create(:ci_build, :running, runner: runner, timeout: 600) }

  subject(:service) { described_class.new }

  before_all do
    FactoryBot::Internal.sequences[:ci_partition_id].rewind
  end

  context 'when job timeout has been exceeded' do
    let(:created_at) { job.timeout.seconds.ago }

    it_behaves_like 'job is dropped with failure reason', 'job_execution_timeout'
    it_behaves_like 'when invalid dooms the job bypassing validations'
  end

  context 'when job timeout has not been exceeded' do
    let(:created_at) { rand(job.timeout.seconds.ago..Time.current) }

    it_behaves_like 'job is unchanged'
  end
end
