# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropRunningService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition) }
  let!(:runner) { create :ci_runner }
  let!(:job) do
    create(:ci_build, :picked, runner: runner, created_at: created_at, updated_at: updated_at, status: status,
      timeout: 1.hour.from_now)
  end

  subject(:service) { described_class.new }

  before_all do
    FactoryBot::Internal.sequences[:ci_partition_id].rewind
  end

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

        it_behaves_like 'job is dropped with failure reason', 'no_updates_running'
        it_behaves_like 'when invalid dooms the job bypassing validations'

        context 'when job becomes successful before processing the drop' do
          it 'does not doom the successful job' do
            allow(service).to receive(:drop_build).and_wrap_original do |method, *args|
              job.success!
              method.call(*args)
            end

            service.execute

            expect(job.reload.status).to eq('success')
          end
        end

        context 'when job is timed out' do
          before do
            job.update!(timeout: 1.minute.ago)
          end

          it_behaves_like 'job is unchanged'
        end
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

  context 'when job is not running' do
    let!(:job) do
      create(:ci_build, runner: runner, created_at: created_at, updated_at: updated_at, status: status)
    end

    let(:updated_at) { 2.days.ago }

    %w[success skipped failed canceled scheduled pending].each do |status|
      context "when job is #{status}" do
        let(:status) { status }

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
end
