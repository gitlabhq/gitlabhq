# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Organizations::Organization, feature_category: :cell do
  let(:avatar_url) { 'https://example.com/uploads/-/system/organizations/organization_detail/avatar/1/avatar.png' }
  let(:organization) { build_stubbed(:organization) }

  subject(:json) { described_class.new(organization).as_json }

  before do
    allow(organization).to receive(:avatar_url).with(only_path: false).and_return(avatar_url)
  end

  it 'exposes all the correct attributes' do
    expect(json).to match_array(
      id: organization.id,
      name: organization.name,
      path: organization.path,
      description: organization.description,
      created_at: organization.created_at,
      updated_at: organization.updated_at,
      web_url: organization.web_url,
      avatar_url: avatar_url
    )
  end
end
