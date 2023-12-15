# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::ProjectGroupLinkEntity, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_group_link) { create(:project_group_link) }

  let(:entity) { described_class.new(project_group_link, { current_user: current_user, source: project_group_link.project }) }

  subject(:as_json) do
    entity.as_json
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/project_group_link')
  end

  context 'when current user is a direct member' do
    before do
      allow(entity).to receive(:direct_member?).and_return(true)
      allow(entity).to receive(:can?).and_call_original
    end

    describe 'can_update' do
      using RSpec::Parameterized::TableSyntax

      where(
        :can_admin_project_member,
        :can_manage_group_link_with_owner_access,
        :expected_can_update
      ) do
        false | false | false
        true  | false | false
        true  | true  | true
      end

      with_them do
        before do
          allow(entity)
            .to receive(:can?)
            .with(current_user, :admin_project_member, project_group_link.shared_from)
            .and_return(can_admin_project_member)
          allow(entity)
            .to receive(:can?)
            .with(current_user, :manage_group_link_with_owner_access, project_group_link)
            .and_return(can_manage_group_link_with_owner_access)
        end

        it "exposes `can_update` as `#{params[:expected_can_update]}`" do
          expect(entity.as_json[:can_update]).to be expected_can_update
        end
      end
    end

    describe 'can_remove' do
      context 'when current user has `destroy_project_group_link` ability' do
        before do
          allow(entity)
            .to receive(:can?)
            .with(current_user, :destroy_project_group_link, project_group_link)
            .and_return(true)
        end

        it 'exposes `can_remove` as `true`' do
          expect(entity.as_json[:can_remove]).to be(true)
        end
      end

      context 'when current user does not have `destroy_project_group_link` ability' do
        before do
          allow(entity)
            .to receive(:can?)
            .with(current_user, :destroy_project_group_link, project_group_link)
            .and_return(false)
        end

        it 'exposes `can_remove` as `false`' do
          expect(entity.as_json[:can_remove]).to be(false)
        end
      end
    end
  end

  context 'when current user is not a direct member' do
    before do
      allow(entity).to receive(:direct_member?).and_return(false)
    end

    it 'exposes `can_update` and `can_remove` as `false`' do
      json = entity.as_json

      expect(json[:can_update]).to be false
      expect(json[:can_remove]).to be false
    end
  end

  context 'when current user is not a project member' do
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
