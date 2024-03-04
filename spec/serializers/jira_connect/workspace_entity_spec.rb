# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::WorkspaceEntity, feature_category: :integrations do
  subject(:serializer) { described_class.represent(namespace).as_json }

  let(:namespace) { build_stubbed(:group) }

  it 'contains all necessary elements of the group' do
    expect(serializer[:id]).to eq(namespace.id)
    expect(serializer[:name]).to eq(namespace.name)
    expect(serializer[:avatarUrl]).to eq(namespace.avatar_url)
  end
end
