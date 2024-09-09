# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropScheduledService, feature_category: :continuous_integration do
  let_it_be(:runner) { create :ci_runner }

  let!(:job) { create :ci_build, :scheduled, scheduled_at: scheduled_at, runner: runner }

  subject(:service) { described_class.new }

  context 'when job is scheduled' do
    context 'for more than an hour ago' do
      let(:scheduled_at) { 2.hours.ago }

      it_behaves_like 'job is dropped with failure reason', 'stale_schedule'
      it_behaves_like 'when invalid dooms the job bypassing validations'
    end

    context 'for less than 1 hour ago' do
      let(:scheduled_at) { 30.minutes.ago }

      it_behaves_like 'job is unchanged'
    end
  end

  %w[success skipped failed canceled running pending].each do |status|
    context "when job is #{status}" do
      before do
        job.update!(status: status)
      end

      context 'and scheduled for more than an hour ago' do
        let(:scheduled_at) { 2.hours.ago }

        it_behaves_like 'job is unchanged'
      end

      context 'and scheduled for less than 1 hour ago' do
        let(:scheduled_at) { 30.minutes.ago }

        it_behaves_like 'job is unchanged'
      end
    end
  end

  context 'when there are no stale scheduled builds' do
    let(:job) {}

    it 'does not drop the stale scheduled build yet' do
      expect { service.execute }.not_to raise_error
    end
  end
end
