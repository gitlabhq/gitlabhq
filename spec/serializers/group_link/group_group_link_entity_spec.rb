# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::GroupGroupLinkEntity, feature_category: :groups_and_projects do
  include_context 'group_group_link'

  let_it_be(:current_user) { create(:user) }

  let(:entity) { described_class.new(group_group_link, { current_user: current_user, source: shared_group }) }

  subject(:as_json) do
    entity.as_json
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/group_group_link')
  end

  it 'correctly exposes `valid_roles`' do
    expect(entity.as_json[:valid_roles]).to include(Gitlab::Access.options_with_owner)
  end

  context 'source' do
    it 'exposes `source`' do
      expect(as_json[:source]).to include(
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

  context 'when current user has owner permissions for the shared group' do
    before_all do
      shared_group.add_owner(current_user)
    end

    context 'when direct_member? is true' do
      before do
        allow(entity).to receive(:direct_member?).and_return(true)
      end

      it 'exposes `can_update` and `can_remove` as `true`' do
        expect(as_json[:can_update]).to be true
        expect(as_json[:can_remove]).to be true
      end
    end

    context 'when direct_member? is false' do
      before do
        allow(entity).to receive(:direct_member?).and_return(false)
      end

      it 'exposes `can_update` and `can_remove` as `false`' do
        expect(as_json[:can_update]).to be false
        expect(as_json[:can_remove]).to be false
      end
    end
  end

  context 'when current user is not a group member' do
    context 'when shared with group is public' do
      it 'does expose shared_with_group details' do
        expect(as_json[:shared_with_group].keys).to include(:id, :avatar_url, :web_url, :name)
      end

      it 'does expose source details' do
        expect(as_json[:source].keys).to include(:id, :full_name)
      end

      it 'sets is_shared_with_group_private to false' do
        expect(as_json[:is_shared_with_group_private]).to be false
      end
    end

    context 'when shared with group is private' do
      let_it_be(:shared_with_group) { create(:group, :private) }

      let_it_be(:group_group_link) do
        create(
          :group_group_link,
          {
            shared_group: shared_group,
            shared_with_group: shared_with_group,
            expires_at: '2020-05-12'
          }
        )
      end

      it 'does not expose shared_with_group details' do
        expect(as_json[:shared_with_group].keys).to contain_exactly(:id)
      end

      it 'does not expose source details' do
        expect(as_json[:source]).to be_nil
      end

      it 'sets is_shared_with_group_private to true' do
        expect(as_json[:is_shared_with_group_private]).to be true
      end
    end
  end
end
