# frozen_string_literal: true

# Shared examples asserting that a token carrying only the `ai_workflows` scope can read
# emoji reactions on an awardable but cannot add or remove them.
#
# The examples expect these to be defined in the calling spec:
# - `user` the token owner, who is allowed to read `awardable`
# - `awardable` the object the reactions belong to
# - `award_emoji` an existing reaction on `awardable`
# - `request_path` the award emoji collection path for `awardable`
#
RSpec.shared_examples 'read-only award emoji access for the ai_workflows scope' do
  let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

  it 'returns an array of award emoji' do
    get api(request_path, oauth_access_token: oauth_token)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first['name']).to eq(award_emoji.name)
  end

  it 'returns a single award emoji' do
    get api("#{request_path}/#{award_emoji.id}", oauth_access_token: oauth_token)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['name']).to eq(award_emoji.name)
  end

  it 'allows a HEAD request' do
    head api(request_path, oauth_access_token: oauth_token)

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'does not allow adding an award emoji' do
    expect do
      post api(request_path, oauth_access_token: oauth_token), params: { name: 'blowfish' }

      expect(response).to have_gitlab_http_status(:forbidden)
    end.not_to change { awardable.award_emoji.count }
  end

  it 'does not allow deleting an award emoji' do
    expect do
      delete api("#{request_path}/#{award_emoji.id}", oauth_access_token: oauth_token)

      expect(response).to have_gitlab_http_status(:forbidden)
    end.not_to change { awardable.award_emoji.count }
  end
end
