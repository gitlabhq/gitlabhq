# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::ProjectGroupLinkEntity do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_group_link) { create(:project_group_link) }

  let(:entity) { described_class.new(project_group_link, { current_user: current_user, source: project_group_link.project }) }

  subject(:as_json) do
    entity.as_json
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/project_group_link')
  end

  context 'when current user is a project maintainer' do
    before_all do
      project_group_link.project.add_maintainer(current_user)
    end

    it 'exposes `can_update` and `can_remove` as `true`' do
      expect(as_json[:can_update]).to be true
      expect(as_json[:can_remove]).to be true
    end
  end

  context 'when current user is a group owner' do
    before_all do
      project_group_link.group.add_owner(current_user)
    end

    it 'exposes `can_remove` as true' do
      expect(as_json[:can_remove]).to be true
    end
  end

  context 'when current user is not a group owner' do
    it 'exposes `can_remove` as false' do
      expect(as_json[:can_remove]).to be false
    end

    context 'when group is public' do
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

    context 'when group is private' do
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:project_group_link) { create(:project_group_link, group: private_group) }

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
