# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropPendingService, feature_category: :continuous_integration do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }
  let_it_be_with_reload(:job) do
    create(:ci_build, pipeline: pipeline, runner: runner)
  end

  let(:created_at) {}
  let(:updated_at) {}

  subject(:service) { described_class.new }

  before do
    job_attributes = { status: status }
    job_attributes[:created_at] = created_at if created_at
    job_attributes[:updated_at] = updated_at if updated_at
    job_attributes.compact!

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

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
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

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
        end

        context 'when created_at is before updated_at' do
          let(:created_at) { 3.days.ago }

          it_behaves_like 'job is dropped with failure reason', 'stuck_or_timeout_failure'
          it_behaves_like 'when invalid dooms the job bypassing validations'
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

  %w[success skipped failed canceled].each do |status|
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

  context 'for deleted project' do
    let(:status) { 'running' }
    let(:updated_at) { 2.days.ago }

    before do
      job.project.update!(pending_delete: true)
    end

    it_behaves_like 'job is unchanged'
  end
end
