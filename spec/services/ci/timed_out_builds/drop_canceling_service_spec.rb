# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropCancelingService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition) }
  let!(:runner) { create :ci_runner }
  let(:timeout) { 600 }
  let!(:job) { create(:ci_build, :canceling, started_at: started_at, runner: runner, timeout: timeout) }

  subject(:service) { described_class.new }

  before_all do
    FactoryBot::Internal.sequences[:ci_partition_id].rewind
  end

  before do
    stub_feature_flags(enforce_job_timeouts_on_canceling_jobs: true)
  end

  context 'when job timeout has been exceeded' do
    let(:started_at) { timeout.seconds.ago }

    it_behaves_like 'job is canceled with failure reason', 'job_execution_server_timeout'
    it_behaves_like 'when invalid dooms the job bypassing validations'

    context 'when enforce_job_timeouts_on_canceling_jobs is disabled' do
      before do
        stub_feature_flags(enforce_job_timeouts_on_canceling_jobs: false)
      end

      it_behaves_like 'job is unchanged'
    end
  end

  context 'when job timeout has not been exceeded' do
    let(:started_at) { rand(timeout.seconds.ago..Time.current) }

    it_behaves_like 'job is unchanged'
  end
end
