# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupLinkEntity, feature_category: :groups_and_projects do
  include_context 'group_group_link'

  let(:entity) { described_class.new(group_group_link) }
  let(:entity_hash) { entity.as_json }

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/group_link')
  end

  it 'correctly exposes `shared_with_group.avatar_url`' do
    avatar_url = 'https://gitlab.com/uploads/-/system/group/avatar/24/foobar.png?width=40'
    allow(shared_with_group).to receive(:avatar_url).with(only_path: false, size: Member::AVATAR_SIZE).and_return(avatar_url)

    expect(entity_hash[:shared_with_group][:avatar_url]).to match(avatar_url)
  end
end
