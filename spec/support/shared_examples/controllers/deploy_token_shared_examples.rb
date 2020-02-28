# frozen_string_literal: true

RSpec.shared_examples 'a created deploy token' do
  let(:deploy_token_params) do
    {
      name: 'deployer_token',
      expires_at: 1.month.from_now.to_date.to_s,
      username: 'deployer',
      read_repository: '1',
      deploy_token_type: deploy_token_type
    }
  end

  subject(:create_deploy_token) { post :create_deploy_token, params: create_entity_params.merge({ deploy_token: deploy_token_params }) }

  it 'creates deploy token' do
    expect { create_deploy_token }.to change { DeployToken.active.count }.by(1)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to render_template(:show)
  end
end
