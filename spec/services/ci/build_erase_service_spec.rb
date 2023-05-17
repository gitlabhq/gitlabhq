# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildEraseService, feature_category: :continuous_integration do
  let_it_be(:user) { user }

  let(:build) { create(:ci_build, :artifacts, :trace_artifact, artifacts_expire_at: 100.days.from_now) }

  subject(:service) { described_class.new(build, user) }

  describe '#execute' do
    context 'when build is erasable' do
      before do
        allow(build).to receive(:erasable?).and_return(true)
      end

      it 'is successful' do
        result = service.execute

        expect(result).to be_success
      end

      it 'erases artifacts' do
        service.execute

        expect(build.artifacts_file).not_to be_present
        expect(build.artifacts_metadata).not_to be_present
      end

      it 'erases trace' do
        service.execute

        expect(build.trace).not_to exist
      end

      it 'records erasure detail' do
        freeze_time do
          service.execute

          expect(build.erased_by).to eq(user)
          expect(build.erased_at).to eq(Time.current)
          expect(build.artifacts_expire_at).to be_nil
        end
      end

      context 'when project is undergoing statistics refresh' do
        before do
          allow(build.project).to receive(:refreshing_build_artifacts_size?).and_return(true)
        end

        it 'logs a warning' do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger)
            .to receive(:warn_artifact_deletion_during_stats_refresh)
            .with(method: 'Ci::BuildEraseService#execute', project_id: build.project_id)

          service.execute
        end
      end
    end

    context 'when build is not erasable' do
      before do
        allow(build).to receive(:erasable?).and_return(false)
      end

      it 'is not successful' do
        result = service.execute

        expect(result).to be_error
        expect(result.http_status).to eq(:unprocessable_entity)
      end

      it 'does not erase artifacts' do
        service.execute

        expect(build.artifacts_file).to be_present
        expect(build.artifacts_metadata).to be_present
      end

      it 'does not erase trace' do
        service.execute

        expect(build.trace).to exist
      end
    end
  end
end
