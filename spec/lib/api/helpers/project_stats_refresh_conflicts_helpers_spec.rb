# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::ProjectStatsRefreshConflictsHelpers do
  let_it_be(:project) { create(:project) }

  let(:api_class) do
    Class.new do
      include API::Helpers::ProjectStatsRefreshConflictsHelpers
    end
  end

  let(:api_controller) { api_class.new }

  describe '#reject_if_build_artifacts_size_refreshing!' do
    let(:entrypoint) { '/some/thing' }

    before do
      allow(project).to receive(:refreshing_build_artifacts_size?).and_return(refreshing)
      allow(api_controller).to receive_message_chain(:request, :path).and_return(entrypoint)
    end

    context 'when project is undergoing stats refresh' do
      let(:refreshing) { true }

      it 'logs and returns a 409 conflict error' do
        expect(Gitlab::ProjectStatsRefreshConflictsLogger)
          .to receive(:warn_request_rejected_during_stats_refresh)
          .with(project.id)

        expect(api_controller).to receive(:conflict!)

        api_controller.reject_if_build_artifacts_size_refreshing!(project)
      end
    end

    context 'when project is not undergoing stats refresh' do
      let(:refreshing) { false }

      it 'does nothing' do
        expect(Gitlab::ProjectStatsRefreshConflictsLogger).not_to receive(:warn_request_rejected_during_stats_refresh)
        expect(api_controller).not_to receive(:conflict)

        api_controller.reject_if_build_artifacts_size_refreshing!(project)
      end
    end
  end
end
