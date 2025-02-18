# frozen_string_literal: true

RSpec.shared_examples 'GET resource access tokens available' do
  let_it_be(:active_resource_access_token) { create(:personal_access_token, user: access_token_user) }

  before_all do
    create(:personal_access_token, :expired, user: access_token_user)
    create(:personal_access_token, :revoked, user: access_token_user)
    create(:personal_access_token, :revoked, user: access_token_user)
  end

  it 'retrieves active access tokens' do
    get_access_tokens

    token_entities = assigns(:active_access_tokens)
    expect(token_entities.length).to eq(1)
    expect(token_entities[0][:name]).to eq(active_resource_access_token.name)
  end

  it 'lists all available scopes' do
    get_access_tokens

    expect(assigns(:scopes)).to eq(Gitlab::Auth.available_scopes_for(resource))
  end

  it 'retrieves count of active access tokens' do
    get_access_tokens

    expect(assigns(:active_access_tokens_size)).to eq(assigns(:active_access_tokens).size)
  end

  it 'retrieves count of inactive access tokens' do
    get_access_tokens

    expect(assigns(:inactive_access_tokens_size)).to eq(3)
  end

  it 'returns for json response list of active access tokens' do
    get_access_tokens_json

    expect(json_response.count).to eq(1)
    expect(json_response.first['id']).to eq(active_resource_access_token.id)
  end
end

RSpec.shared_examples 'GET access tokens are paginated and ordered' do
  before do
    create(:personal_access_token, user: access_token_user)
  end

  context "when multiple access tokens are returned" do
    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      create(:personal_access_token, user: access_token_user)
    end

    it "returns paginated response", :aggregate_failures do
      get_access_tokens_with_page
      expect(assigns(:active_access_tokens).count).to eq(1)

      expect_header('X-Per-Page', '1')
      expect_header('X-Page', '1')
      expect_header('X-Next-Page', '2')
      expect_header('X-Total', '2')
    end
  end

  context "when active tokens returned are ordered" do
    let(:expires_1_day_from_now) { 1.day.from_now.to_date }
    let(:expires_2_day_from_now) { 2.days.from_now.to_date }

    before do
      create(:personal_access_token, user: access_token_user, name: "Token1", expires_at: expires_1_day_from_now)
      create(:personal_access_token, user: access_token_user, name: "Token2", expires_at: expires_2_day_from_now)
    end

    it "orders token list ascending on expires_at" do
      get_access_tokens

      first_token = assigns(:active_access_tokens).first.as_json
      expect(first_token['name']).to eq("Token1")
      expect(first_token['expires_at']).to eq(expires_1_day_from_now.iso8601)
    end

    it "orders tokens on id in case token has same expires_at" do
      create(:personal_access_token, user: access_token_user, name: "Token3", expires_at: expires_1_day_from_now)

      get_access_tokens

      first_token = assigns(:active_access_tokens).first.as_json
      expect(first_token['name']).to eq("Token3")
      expect(first_token['expires_at']).to eq(expires_1_day_from_now.iso8601)

      second_token = assigns(:active_access_tokens).second.as_json
      expect(second_token['name']).to eq("Token1")
      expect(second_token['expires_at']).to eq(expires_1_day_from_now.iso8601)
    end
  end

  def expect_header(header_name, header_val)
    expect(response.headers[header_name]).to eq(header_val)
  end
end

RSpec.shared_examples 'GET inactive access tokens' do
  let_it_be(:inactive_resource_access_token1) { create(:personal_access_token, :expired, user: access_token_user) }
  let_it_be(:inactive_resource_access_token2) { create(:personal_access_token, :revoked, user: access_token_user) }
  let_it_be(:inactive_resource_access_token3) { create(:personal_access_token, :revoked, user: access_token_user) }

  before_all do
    create(:personal_access_token, user: access_token_user)
  end

  it 'returns list of inactive access tokens' do
    get_inactive_access_tokens

    expect(json_response.count).to eq(3)
  end

  it 'returns list of inactive access tokens in descending order by updated_at', :aggregate_failures do
    inactive_resource_access_token1.update!(updated_at: 4.days.ago)
    inactive_resource_access_token2.update!(updated_at: 2.days.ago)
    inactive_resource_access_token3.update!(updated_at: 3.days.ago)

    get_inactive_access_tokens

    expect(json_response.count).to eq(3)
    expect(json_response.pluck('id')).to eq(
      [
        inactive_resource_access_token1,
        inactive_resource_access_token2,
        inactive_resource_access_token3
      ].sort_by(&:updated_at).reverse.pluck(:id)
    )
  end

  it "returns paginated response", :aggregate_failures do
    get_inactive_access_tokens

    expect(response).to include_pagination_headers
    expect(response.headers['X-Per-Page']).to eq('20')
    expect(response.headers['X-Page']).to eq('1')
    expect(response.headers['X-Next-Page']).to eq('')
    expect(response.headers['X-Total']).to eq('3')
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
    expect(parsed_body['active_access_tokens'].length).to be > 0
    expect(parsed_body['total']).to be > 0
    expect(parsed_body['errors']).to be_blank
    expect(response).to have_gitlab_http_status(:success)
  end

  it 'creates resource access token' do
    access_level = access_token_params[:access_level] || Gitlab::Access::MAINTAINER
    subject

    expect(created_token.name).to eq(access_token_params[:name])
    expect(created_token.description).to eq(access_token_params[:description])
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
  it 'revokes the token' do
    subject
    expect(resource_access_token.reload).to be_revoked
  end

  it 'does not call delete user worker' do
    expect(DeleteUserWorker).not_to receive(:perform_async)
    subject
  end

  it 'does not remove membership of the bot' do
    subject

    resource_bots = if resource.is_a?(Project)
                      resource.bots
                    elsif resource.is_a?(Group)
                      User.bots.id_in(resource.all_group_members.non_invite.pluck(:user_id))
                    end

    expect(resource_bots).to include(access_token_user)
  end

  it 'does not create GhostUserMigration records to handle migration in a worker' do
    expect { subject }.not_to change { Users::GhostUserMigration.count }
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
