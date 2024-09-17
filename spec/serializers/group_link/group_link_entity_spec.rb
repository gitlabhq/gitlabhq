# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupLinkEntity, feature_category: :groups_and_projects do
  include_context 'group_group_link'

  let(:source) { shared_group }
  let(:entity) { described_class.new(group_group_link, { source: source }) }
  let(:entity_hash) { entity.as_json }

  shared_examples 'exposes source type properties' do |is_direct_member, is_inherited_member|
    it "exposes `is_direct_member` as `#{is_direct_member}`" do
      expect(entity_hash[:is_direct_member]).to be(is_direct_member)
    end

    it "exposes `is_inherited_member` as `#{is_inherited_member}`" do
      expect(entity_hash[:is_inherited_member]).to be(is_inherited_member)
    end
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/group_link')
  end

  it 'correctly exposes `shared_with_group.avatar_url`' do
    avatar_url = 'https://gitlab.com/uploads/-/system/group/avatar/24/foobar.png?width=40'
    allow(shared_with_group).to receive(:avatar_url).with(only_path: false, size: Member::AVATAR_SIZE).and_return(avatar_url)

    expect(entity_hash[:shared_with_group][:avatar_url]).to match(avatar_url)
  end

  context 'for direct member' do
    it_behaves_like 'exposes source type properties', true, false
  end

  context 'for inherited member' do
    let_it_be(:subgroup) { build_stubbed(:group, parent: shared_group) }
    let(:source) { subgroup }

    it_behaves_like 'exposes source type properties', false, true
  end
end
