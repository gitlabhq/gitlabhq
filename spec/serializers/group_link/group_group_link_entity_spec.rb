# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupGroupLinkEntity do
  include_context 'group_group_link'

  let_it_be(:current_user) { create(:user) }

  let(:entity) { described_class.new(group_group_link) }

  before do
    allow(entity).to receive(:current_user).and_return(current_user)
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/group_group_link')
  end

  context 'when current user has `:admin_group_member` permissions' do
    before do
      allow(entity).to receive(:can?).with(current_user, :admin_group_member, shared_group).and_return(true)
    end

    it 'exposes `can_update` and `can_remove` as `true`' do
      json = entity.as_json

      expect(json[:can_update]).to be true
      expect(json[:can_remove]).to be true
    end
  end
end
