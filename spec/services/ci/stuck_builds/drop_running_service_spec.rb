# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropRunningService, feature_category: :continuous_integration do
  let!(:runner) { create :ci_runner }
  let!(:job) { create(:ci_build, runner: runner, created_at: created_at, updated_at: updated_at, status: status) }

  subject(:service) { described_class.new }

  around do |example|
    freeze_time { example.run }
  end

  shared_examples 'running builds' do
    context 'when job is running' do
      let(:status) { 'running' }
      let(:outdated_time) { described_class::BUILD_RUNNING_OUTDATED_TIMEOUT.ago - 30.minutes }
      let(:fresh_time) { described_class::BUILD_RUNNING_OUTDATED_TIMEOUT.ago + 30.minutes }

      context 'when job is outdated' do
        let(:created_at) { outdated_time }
        let(:updated_at) { outdated_time }

        it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
        it_behaves_like 'when invalid dooms the job bypassing validations'
      end

      context 'when job is fresh' do
        let(:created_at) { fresh_time }
        let(:updated_at) { fresh_time }

        it_behaves_like 'job is unchanged'
      end

      context 'when job freshly updated' do
        let(:created_at) { outdated_time }
        let(:updated_at) { fresh_time }

        it_behaves_like 'job is unchanged'
      end
    end
  end

  include_examples 'running builds'

  %w[success skipped failed canceled scheduled pending].each do |status|
    context "when job is #{status}" do
      let(:status) { status }
      let(:updated_at) { 2.days.ago }

      context 'when created_at is the same as updated_at' do
        let(:created_at) { 2.days.ago }

        it_behaves_like 'job is unchanged'
      end

      context 'when created_at is before updated_at' do
        let(:created_at) { 3.days.ago }

        it_behaves_like 'job is unchanged'
      end
    end
  end
end
