# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DeleteService, feature_category: :job_artifacts do
  let_it_be(:build, reload: true) do
    create(:ci_build, :artifacts, :trace_artifact, artifacts_expire_at: 100.days.from_now)
  end

  subject(:service) { described_class.new(build) }

  describe '#execute' do
    it 'is successful' do
      result = service.execute

      expect(result).to be_success
      expect(result[:destroyed_artifacts_count]).to be(2)
    end

    it 'deletes erasable artifacts' do
      expect { service.execute }.to change { build.job_artifacts.erasable.count }.from(2).to(0)
    end

    it 'does not delete trace' do
      expect { service.execute }.not_to change { build.has_trace? }.from(true)
    end

    context 'when project is undergoing stats refresh' do
      before do
        allow(build.project).to receive(:refreshing_build_artifacts_size?).and_return(true)
      end

      it 'logs a warning' do
        expect(Gitlab::ProjectStatsRefreshConflictsLogger)
          .to receive(:warn_artifact_deletion_during_stats_refresh)
                .with(method: 'Ci::JobArtifacts::DeleteService#execute', project_id: build.project_id)

        service.execute
      end

      it 'returns an error response with the correct message and reason' do
        result = service.execute

        expect(result).to be_error
        expect(result[:message]).to be('Action temporarily disabled. ' \
          'The project this job belongs to is undergoing stats refresh.')
        expect(result[:reason]).to be(:project_stats_refresh)
      end
    end

    context 'when an error response is received from DestroyBatchService' do
      before do
        allow_next_instance_of(Ci::JobArtifacts::DestroyBatchService) do |service|
          allow(service).to receive(:execute).and_return({ status: :error, message: 'something went wrong' })
        end
      end

      it 'returns an error response with the correct message' do
        result = service.execute

        expect(result).to be_error
        expect(result[:message]).to be('something went wrong')
      end
    end
  end
end
