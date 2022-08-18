# frozen_string_literal: true

RSpec.shared_examples_for 'when the user cannot read cross project' do |action, params|
  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, :read_cross_project, :global).and_return(false)
  end

  it 'blocks access without a project_id' do
    get action, params: params

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'allows access with a project_id' do
    get action, params: params.merge(project_id: create(:project, :public).id)

    expect(response).to have_gitlab_http_status(:ok)
  end
end
