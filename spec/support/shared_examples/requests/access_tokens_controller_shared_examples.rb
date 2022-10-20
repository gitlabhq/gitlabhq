# frozen_string_literal: true

RSpec.shared_examples 'GET resource access tokens available' do
  let_it_be(:active_resource_access_token) { create(:personal_access_token, user: bot_user) }

  it 'retrieves active resource access tokens' do
    subject

    token_entities = assigns(:active_resource_access_tokens)
    expect(token_entities.length).to eq(1)
    expect(token_entities[0][:name]).to eq(active_resource_access_token.name)
  end

  it 'lists all available scopes' do
    subject

    expect(assigns(:scopes)).to eq(Gitlab::Auth.resource_bot_scopes)
  end
end

RSpec.shared_examples 'POST resource access tokens available' do
  def created_token
    PersonalAccessToken.order(:created_at).last
  end

  it 'renders JSON with a token' do
    subject

    parsed_body = Gitlab::Json.parse(response.body)
    expect(parsed_body['new_token']).not_to be_blank
    expect(parsed_body['errors']).to be_blank
    expect(response).to have_gitlab_http_status(:success)
  end

  it 'creates resource access token' do
    access_level = access_token_params[:access_level] || Gitlab::Access::MAINTAINER
    subject

    expect(created_token.name).to eq(access_token_params[:name])
    expect(created_token.scopes).to eq(access_token_params[:scopes])
    expect(created_token.expires_at).to eq(access_token_params[:expires_at])
    expect(resource.member(created_token.user).access_level).to eq(access_level)
  end

  it 'creates project bot user' do
    subject

    expect(created_token.user).to be_project_bot
  end

  it { expect { subject }.to change { User.count }.by(1) }
  it { expect { subject }.to change { PersonalAccessToken.count }.by(1) }

  context 'when unsuccessful' do
    before do
      allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
        allow(service).to receive(:execute).and_return ServiceResponse.error(message: 'Failed!')
      end
    end

    it 'does not create the token' do
      expect { subject }.not_to change { PersonalAccessToken.count }
    end

    it 'does not add the project bot as a member' do
      expect { subject }.not_to change { Member.count }
    end

    it 'does not create the project bot user' do
      expect { subject }.not_to change { User.count }
    end

    it 'renders JSON with an error' do
      subject

      parsed_body = Gitlab::Json.parse(response.body)
      expect(parsed_body['new_token']).to be_blank
      expect(parsed_body['errors']).to contain_exactly('Failed!')
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end
end

RSpec.shared_examples 'PUT resource access tokens available' do
  it 'calls delete user worker' do
    expect(DeleteUserWorker).to receive(:perform_async).with(user.id, bot_user.id, skip_authorization: true)

    subject
  end

  it 'removes membership of bot user' do
    subject

    expect(resource.reload.bots).not_to include(bot_user)
  end

  context 'when user_destroy_with_limited_execution_time_worker is enabled' do
    it 'creates GhostUserMigration records to handle migration in a worker' do
      expect { subject }.to(
        change { Users::GhostUserMigration.count }.from(0).to(1))
    end
  end

  context 'when user_destroy_with_limited_execution_time_worker is disabled' do
    before do
      stub_feature_flags(user_destroy_with_limited_execution_time_worker: false)
    end

    it 'converts issuables of the bot user to ghost user' do
      issue = create(:issue, author: bot_user)

      subject

      expect(issue.reload.author.ghost?).to be true
    end

    it 'deletes project bot user' do
      subject

      expect(User.exists?(bot_user.id)).to be_falsy
    end
  end

  context 'when unsuccessful' do
    before do
      allow_next_instance_of(ResourceAccessTokens::RevokeService) do |service|
        allow(service).to receive(:execute).and_return ServiceResponse.error(message: 'Failed!')
      end
    end

    it 'shows a failure alert' do
      subject

      expect(flash[:alert]).to include("Could not revoke access token")
    end
  end
end
