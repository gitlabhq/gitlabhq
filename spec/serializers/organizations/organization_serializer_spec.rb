# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationSerializer, feature_category: :organization do
  let(:organization) { build_stubbed(:organization) }

  subject(:json) { described_class.new.represent(organization) }

  # Guards the public API entity this serializer reuses: a field exposed there
  # would otherwise silently appear in internal responses.
  it 'exposes only the expected attributes' do
    expect(json.keys).to match_array(
      %i[id uuid name path description visibility created_at updated_at web_url avatar_url]
    )
  end

  it 'exposes the organization' do
    expect(json).to include(id: organization.id, name: organization.name, path: organization.path)
  end
end
