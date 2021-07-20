# frozen_string_literal: true

RSpec.shared_examples 'project access tokens available #index' do
  let_it_be(:active_project_access_token) { create(:personal_access_token, user: bot_user) }
  let_it_be(:inactive_project_access_token) { create(:personal_access_token, :revoked, user: bot_user) }

  it 'retrieves active project access tokens' do
    subject

    expect(assigns(:active_project_access_tokens)).to contain_exactly(active_project_access_token)
  end

  it 'retrieves inactive project access tokens' do
    subject

    expect(assigns(:inactive_project_access_tokens)).to contain_exactly(inactive_project_access_token)
  end

  it 'lists all available scopes' do
    subject

    expect(assigns(:scopes)).to eq(Gitlab::Auth.resource_bot_scopes)
  end

  it 'retrieves newly created personal access token value' do
    token_value = 'random-value'
    allow(PersonalAccessToken).to receive(:redis_getdel).with("#{user.id}:#{project.id}").and_return(token_value)

    subject

    expect(assigns(:new_project_access_token)).to eq(token_value)
  end
end

RSpec.shared_examples 'project access tokens available #create' do
  def created_token
    PersonalAccessToken.order(:created_at).last
  end

  it 'returns success message' do
    subject

    expect(controller).to set_flash[:notice].to match('Your new project access token has been created.')
  end

  it 'creates project access token' do
    access_level = access_token_params[:access_level] || Gitlab::Access::MAINTAINER
    subject

    expect(created_token.name).to eq(access_token_params[:name])
    expect(created_token.scopes).to eq(access_token_params[:scopes])
    expect(created_token.expires_at).to eq(access_token_params[:expires_at])
    expect(project.project_member(created_token.user).access_level).to eq(access_level)
  end

  it 'creates project bot user' do
    subject

    expect(created_token.user).to be_project_bot
  end

  it 'stores newly created token redis store' do
    expect(PersonalAccessToken).to receive(:redis_store!)

    subject
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

    it 'shows a failure alert' do
      subject

      expect(controller).to set_flash[:alert].to match("Failed to create new project access token: Failed!")
    end
  end
end

RSpec.shared_examples 'project access tokens available #revoke' do
  it 'calls delete user worker' do
    expect(DeleteUserWorker).to receive(:perform_async).with(user.id, bot_user.id, skip_authorization: true)

    subject
  end

  it 'removes membership of bot user' do
    subject

    expect(project.reload.bots).not_to include(bot_user)
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
