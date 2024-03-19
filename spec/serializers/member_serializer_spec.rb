# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberSerializer, feature_category: :groups_and_projects do
  include MembersPresentation
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }

  subject(:representation) do
    described_class.new.represent(members, { current_user: current_user, group: group, source: source }).to_json
  end

  shared_examples 'members.json' do
    it { is_expected.to match_schema('members') }
  end

  shared_examples 'shared source members' do
    let_it_be(:member_user) { create(:user) }
    let(:shared_source) { create(source_type, shared_source_visibility) }
    let(:invited_group) { create(:group, invited_group_visibility) }
    let(:source) { shared_source }
    let(:group) { source.is_a?(Project) ? source.group : source }
    let(:invited_member) { invited_group.add_developer(member_user) }
    let(:members) { present_members([invited_member]) }

    shared_examples 'exposes source correctly' do
      with_them do
        before do
          create_link(source, invited_group)
        end

        specify do
          representation

          expect(invited_member.is_source_accessible_to_current_user).to eq(can_see_invited_members_source?)
        end
      end
    end

    context 'when current user is unauthenticated' do
      let(:current_user) { nil }

      where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
        :public  | :public  | true
        :public  | :private | false
      end

      include_examples 'exposes source correctly'
    end

    context 'when current user non-member of shared source' do
      where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
        :public  | :public  | true
        :public  | :private | false
      end

      include_examples 'exposes source correctly'
    end

    context 'when current user a member of shared source but not of invited group' do
      before do
        shared_source.add_developer(current_user)
      end

      where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
        :public  | :public  | true
        :public  | :private | false
        :private | :public  | true
        :private | :private | false
      end

      include_examples 'exposes source correctly'
    end

    context 'when current user can manage member of shared group but not invited group members' do
      before do
        shared_source.add_member(current_user, admin_member_access)
      end

      where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
        :public  | :public  | true
        :public  | :private | true
        :private | :public  | true
        :private | :private | true
      end

      include_examples 'exposes source correctly'
    end
  end

  context 'group member' do
    let_it_be(:group) { create(:group) }
    let_it_be(:members) { present_members(create_list(:group_member, 1, group: group)) }

    let(:source) { group }

    it_behaves_like 'members.json'

    it 'handles last group owner assignment' do
      group_member = members.last

      expect { representation }.to change(group_member, :last_owner)
                                     .from(nil).to(true)
    end

    it_behaves_like 'shared source members' do
      let_it_be(:source_type) { :group }
      let_it_be(:admin_member_access) { Gitlab::Access::OWNER }

      def create_link(shared, invited)
        create(:group_group_link, shared_group: shared, shared_with_group: invited)
      end
    end
  end

  context 'project member' do
    let_it_be(:project) { create(:project) }
    let_it_be(:members) { present_members(create_list(:project_member, 1, project: project)) }

    let(:source) { project }
    let(:group) { project.group }

    it_behaves_like 'members.json'

    it 'does not invoke group owner assignment' do
      expect(LastGroupOwnerAssigner).not_to receive(:new)

      representation
    end

    it_behaves_like 'shared source members' do
      let_it_be(:source_type) { :project }
      let_it_be(:admin_member_access) { Gitlab::Access::MAINTAINER }

      def create_link(shared, invited)
        create(:project_group_link, project: shared, group: invited)
      end
    end
  end
end
