# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Coverage::Report, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:success_pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:running_pipeline) { create(:ci_pipeline, :running, project: project) }
  let_it_be(:failure_pipeline) { create(:ci_pipeline, :failed, project: project) }

  let_it_be(:builds) do
    [
      create(:ci_build, :success, pipeline: success_pipeline, coverage: 40, created_at: 9.seconds.ago, name: 'coverage'),
      create(:ci_build, :success, pipeline: success_pipeline, coverage: 60, created_at: 8.seconds.ago)
    ]
  end

  let(:badge) do
    described_class.new(project, 'master', opts: { job: job_name })
  end

  let(:job_name) { nil }

  describe '#entity' do
    it 'describes a coverage' do
      expect(badge.entity).to eq 'coverage'
    end
  end

  describe '#metadata' do
    it 'returns correct metadata' do
      expect(badge.metadata.image_url).to include 'coverage.svg'
    end
  end

  describe '#template' do
    it 'returns correct template' do
      expect(badge.template.key_text).to eq 'coverage'
    end
  end

  describe '#status' do
    context 'with no job specified' do
      it 'returns the most recent successful pipeline coverage value' do
        expect(badge.status).to eq(50.00)
      end

      context 'and no successful pipelines' do
        before do
          allow(badge).to receive(:successful_pipeline).and_return(nil)
        end

        it 'returns nil' do
          expect(badge.status).to eq(nil)
        end
      end
    end

    context 'with a blank job name' do
      let(:job_name) { ' ' }

      it 'returns the latest successful pipeline coverage value' do
        expect(badge.status).to eq(50.00)
      end
    end

    context 'with an unmatching job name specified' do
      let(:job_name) { 'incorrect name' }

      it 'returns nil' do
        expect(badge.status).to be_nil
      end
    end

    context 'with a matching job name specified' do
      let(:job_name) { 'coverage' }

      it 'returns the pipeline coverage value' do
        expect(badge.status).to eq(40.00)
      end

      context 'with a more recent running pipeline' do
        let!(:another_build) { create(:ci_build, :success, pipeline: running_pipeline, coverage: 20, created_at: 7.seconds.ago, name: 'coverage') }

        it 'returns the running pipeline coverage value' do
          expect(badge.status).to eq(20.00)
        end
      end

      context 'with a more recent failed pipeline' do
        let!(:another_build) { create(:ci_build, :success, pipeline: failure_pipeline, coverage: 10, created_at: 6.seconds.ago, name: 'coverage') }

        it 'returns the failed pipeline coverage value' do
          expect(badge.status).to eq(10.00)
        end
      end

      context 'when latest pipeline for project is blocked' do
        let_it_be(:blocked_pipeline) { create(:ci_pipeline, :blocked, project: project) }

        context 'and the build has finished' do
          let_it_be(:latest_build) { create(:ci_build, :success, pipeline: blocked_pipeline, coverage: 25, created_at: 1.second.ago, name: 'coverage') }

          it 'returns the coverage for the build' do
            expect(badge.status).to eq(25.00)
          end

          context 'with FF show_job_badge_regardless_of_pipeline disabled' do
            before do
              stub_feature_flags(show_job_badge_regardless_of_pipeline: false)
            end

            it 'returns previous build coverage' do
              expect(badge.status).to eq(40.00)
            end
          end
        end

        context 'and the build failed' do
          let_it_be(:latest_build) { create(:ci_build, :failed, pipeline: blocked_pipeline, coverage: 10, created_at: 1.second.ago, name: 'coverage') }

          it 'reverts to the last successful job' do
            expect(badge.status).to eq(40.00)
          end

          context 'with FF show_job_badge_regardless_of_pipeline disabled' do
            before do
              stub_feature_flags(show_job_badge_regardless_of_pipeline: false)
            end

            it 'returns previous build coverage' do
              expect(badge.status).to eq(40.00)
            end
          end
        end
      end
    end
  end
end
