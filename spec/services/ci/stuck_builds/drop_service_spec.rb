# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropService do
  let!(:runner) { create :ci_runner }
  let!(:job) { create :ci_build, runner: runner }
  let(:created_at) { }
  let(:updated_at) { }

  subject(:service) { described_class.new }

  before do
    job_attributes = { status: status }
    job_attributes[:created_at] = created_at if created_at
    job_attributes[:updated_at] = updated_at if updated_at
    job.update!(job_attributes)
  end

  context 'when job is pending' do
    let(:status) { 'pending' }

    context 'when job is not stuck' do
      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:stuck?).and_return(false)
        end
      end

      context 'when job was updated_at more than 1 day ago' do
        let(:updated_at) { 1.5.days.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.days.ago }

          it_behaves_like 'job is dropped'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped'
        end

        context 'when created_at is outside lookback window' do
          let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

          it_behaves_like 'job is unchanged'
        end
      end

      context 'when job was updated less than 1 day ago' do
        let(:updated_at) { 6.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.days.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is outside lookback window' do
          let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

          it_behaves_like 'job is unchanged'
        end
      end

      context 'when job was updated more than 1 hour ago' do
        let(:updated_at) { 2.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 2.hours.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is outside lookback window' do
          let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

          it_behaves_like 'job is unchanged'
        end
      end
    end

    context 'when job is stuck' do
      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:stuck?).and_return(true)
        end
      end

      context 'when job was updated_at more than 1 hour ago' do
        let(:updated_at) { 1.5.hours.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 1.5.hours.ago }

          it_behaves_like 'job is dropped'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped'
        end

        context 'when created_at is outside lookback window' do
          let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

          it_behaves_like 'job is unchanged'
        end
      end

      context 'when job was updated in less than 1 hour ago' do
        let(:updated_at) { 30.minutes.ago }

        context 'when created_at is the same as updated_at' do
          let(:created_at) { 30.minutes.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 2.days.ago }

          it_behaves_like 'job is unchanged'
        end

        context 'when created_at is outside lookback window' do
          let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

          it_behaves_like 'job is unchanged'
        end
      end
    end
  end

  context 'when job is running' do
    let(:status) { 'running' }

    context 'when job was updated_at more than an hour ago' do
      let(:updated_at) { 2.hours.ago }

      it_behaves_like 'job is unchanged'
    end

    context 'when job was updated in less than 1 hour ago' do
      let(:updated_at) { 30.minutes.ago }

      it_behaves_like 'job is unchanged'
    end
  end

  %w(success skipped failed canceled).each do |status|
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

      context 'when created_at is outside lookback window' do
        let(:created_at) { described_class::BUILD_LOOKBACK - 1.day }

        it_behaves_like 'job is unchanged'
      end
    end
  end

  context 'for deleted project' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }

    before do
      job.project.update!(pending_delete: true)
    end

    it_behaves_like 'job is unchanged'
  end

  describe 'drop stale scheduled builds' do
    let(:status) { 'scheduled' }
    let(:updated_at) { }

    context 'when scheduled at 2 hours ago but it is not executed yet' do
      let!(:job) { create(:ci_build, :scheduled, scheduled_at: 2.hours.ago) }

      it 'drops the stale scheduled build' do
        expect(Ci::Build.scheduled.count).to eq(1)
        expect(job).to be_scheduled

        service.execute
        job.reload

        expect(Ci::Build.scheduled.count).to eq(0)
        expect(job).to be_failed
        expect(job).to be_stale_schedule
      end
    end

    context 'when scheduled at 30 minutes ago but it is not executed yet' do
      let!(:job) { create(:ci_build, :scheduled, scheduled_at: 30.minutes.ago) }

      it 'does not drop the stale scheduled build yet' do
        expect(Ci::Build.scheduled.count).to eq(1)
        expect(job).to be_scheduled

        service.execute

        expect(Ci::Build.scheduled.count).to eq(1)
        expect(job).to be_scheduled
      end
    end

    context 'when there are no stale scheduled builds' do
      it 'does not drop the stale scheduled build yet' do
        expect { service.execute }.not_to raise_error
      end
    end
  end
end
