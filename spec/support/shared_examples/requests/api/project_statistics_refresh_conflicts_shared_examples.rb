# frozen_string_literal: true

RSpec.shared_examples 'preventing request because of ongoing project stats refresh' do |entrypoint|
  before do
    create(:project_build_artifacts_size_refresh, :pending, project: project)
  end

  it 'logs about the rejected request' do
    expect(Gitlab::ProjectStatsRefreshConflictsLogger)
      .to receive(:warn_request_rejected_during_stats_refresh)
      .with(project.id)

    make_request
  end

  it 'returns 409 error' do
    make_request

    expect(response).to have_gitlab_http_status(:conflict)
  end
end
