# frozen_string_literal: true

RSpec.shared_examples_for 'with external authorization service enabled' do |action, params|
  include ExternalAuthorizationServiceHelpers

  let(:project) { create(:project, namespace: user.namespace) }
  let(:note) { create(:note_on_issue, project: project) }

  before do
    enable_external_authorization_service_check
  end

  it 'renders a 403 when no project is given' do
    get action, params: params

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'renders a 200 when a project was set' do
    get action, params: params.merge(project_id: project.id)

    expect(response).to have_gitlab_http_status(:ok)
  end
end
