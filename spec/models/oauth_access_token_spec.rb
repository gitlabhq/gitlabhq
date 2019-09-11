# frozen_string_literal: true

require 'spec_helper'

describe OauthAccessToken do
  let(:user) { create(:user) }
  let(:app_one) { create(:oauth_application) }
  let(:app_two) { create(:oauth_application) }
  let(:app_three) { create(:oauth_application) }
  let(:tokens) { described_class.all }

  before do
    create(:oauth_access_token, application_id: app_one.id)
    create_list(:oauth_access_token, 2, resource_owner: user, application_id: app_two.id)
  end

  it 'returns unique owners' do
    expect(tokens.count).to eq(3)
    expect(tokens.distinct_resource_owner_counts([app_one])).to eq({ app_one.id => 1 })
    expect(tokens.distinct_resource_owner_counts([app_two])).to eq({ app_two.id => 1 })
    expect(tokens.distinct_resource_owner_counts([app_three])).to eq({})
    expect(tokens.distinct_resource_owner_counts([app_one, app_two]))
      .to eq({
               app_one.id => 1,
               app_two.id => 1
             })
  end
end
