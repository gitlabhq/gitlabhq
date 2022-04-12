# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupGroupLinkEntity do
  include_context 'group_group_link'

  let_it_be(:current_user) { create(:user) }

  let(:entity) { described_class.new(group_group_link, { current_user: current_user, source: shared_group }) }

  before do
    allow(entity).to receive(:current_user).and_return(current_user)
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/group_group_link')
  end

  context 'source' do
    it 'exposes `source`' do
      expect(entity.as_json[:source]).to include(
        id: shared_group.id,
        full_name: shared_group.full_name,
        web_url: shared_group.web_url
      )
    end
  end

  context 'is_direct_member' do
    it 'exposes `is_direct_member` as true for corresponding group' do
      expect(entity.as_json[:is_direct_member]).to be true
    end

    it 'exposes `is_direct_member` as false for other source' do
      entity = described_class.new(group_group_link, { current_user: current_user, source: shared_with_group })
      expect(entity.as_json[:is_direct_member]).to be false
    end
  end

  context 'when current user has `:admin_group_member` permissions' do
    before do
      allow(entity).to receive(:can?).with(current_user, :admin_group_member, shared_group).and_return(true)
    end

    context 'when direct_member? is true' do
      before do
        allow(entity).to receive(:direct_member?).and_return(true)
      end

      it 'exposes `can_update` and `can_remove` as `true`' do
        json = entity.as_json

        expect(json[:can_update]).to be true
        expect(json[:can_remove]).to be true
      end
    end

    context 'when direct_member? is false' do
      before do
        allow(entity).to receive(:direct_member?).and_return(false)
      end

      it 'exposes `can_update` and `can_remove` as `true`' do
        json = entity.as_json

        expect(json[:can_update]).to be false
        expect(json[:can_remove]).to be false
      end
    end
  end
end
