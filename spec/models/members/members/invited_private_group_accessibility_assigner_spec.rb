# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InvitedPrivateGroupAccessibilityAssigner, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  describe '#execute' do
    shared_examples 'assigns is_source_accessible_to_current_user' do
      let(:current_user) { user }
      let_it_be(:member_user) { create(:user) }

      subject(:assigner) { described_class.new(members, source: source, current_user: current_user) }

      shared_examples 'sets is_source_accessible_to_current_user to true for all members' do
        specify do
          assigner.execute

          expect(members.first.is_source_accessible_to_current_user).to eq(true)
        end
      end

      context 'for direct members' do
        where(source_visibility: %i[public private])

        with_them do
          let(:source) { create(source_type, source_visibility) }
          let(:direct_member) { source.add_developer(member_user) }
          let(:members) { [direct_member] }

          it_behaves_like 'sets is_source_accessible_to_current_user to true for all members'
        end
      end

      context 'for inherited members' do
        where(source_visibility: %i[public private])

        with_them do
          let(:parent) { create(:group, source_visibility) }
          let(:source) { create(source_type, source_visibility, parent_key => parent) }
          let(:inherited_member) { parent.add_developer(member_user) }
          let(:members) { [inherited_member] }

          it_behaves_like 'sets is_source_accessible_to_current_user to true for all members'
        end
      end

      context 'for shared source members' do
        let(:shared_source) { create(source_type, shared_source_visibility) }
        let(:invited_group_parent) { create(:group, invited_group_visibility) }
        let(:invited_group) { create(:group, invited_group_visibility, parent: invited_group_parent) }
        let(:source) { shared_source }
        let(:invited_member) { invited_group.add_developer(member_user) }
        let(:members) { [invited_member] }
        let!(:link) { create_link(source, invited_group) }

        shared_examples 'sets correct is_source_accessible_to_current_user for invited members' do
          with_them do
            specify do
              assigner.execute

              expect(members.first.is_source_accessible_to_current_user).to eq(can_see_invited_members_source?)
            end

            context 'with multiple members belonging to the same source' do
              it 'avoid N+1 queries' do
                assigner # Initialize objects in let blocks
                recorder = ActiveRecord::QueryRecorder.new { assigner.execute }

                members = create_list(:group_member, 3, group: invited_group)

                assigner = described_class.new(members, source: shared_source, current_user: current_user)
                expect { assigner.execute }.not_to exceed_query_limit(recorder)
              end
            end
          end
        end

        context 'when current user is unauthenticated' do
          let(:current_user) { nil }

          where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
            :public  | :public  | true
            :public  | :private | false
          end

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
        end

        context 'when current user non-member of shared source' do
          where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
            :public  | :public  | true
            :public  | :private | false
          end

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
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

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
        end

        context 'when current user is a direct member of shared group and of invited group through sharing' do
          before do
            group = create(:group, :private, developers: current_user)
            create(:group_group_link, shared_group: invited_group, shared_with_group: group)
          end

          where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
            :public  | :public  | true
            :public  | :private | true
            :private | :public  | true
            :private | :private | true
          end

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
        end

        context 'when current user is a direct member of shared group and of invited group through inheritance' do
          before do
            invited_group_parent.add_developer(current_user)
          end

          where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
            :public  | :public  | true
            :public  | :private | true
            :private | :public  | true
            :private | :private | true
          end

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
        end

        context 'when current user can manage member of shared group not invited group members' do
          before do
            shared_source.add_member(current_user, admin_member_access)
          end

          where(:shared_source_visibility, :invited_group_visibility, :can_see_invited_members_source?) do
            :public  | :public  | true
            :public  | :private | true
            :private | :public  | true
            :private | :private | true
          end

          include_examples 'sets correct is_source_accessible_to_current_user for invited members'
        end
      end
    end

    context 'for project members' do
      let_it_be(:source_type) { 'project' }
      let_it_be(:admin_member_access) { Gitlab::Access::MAINTAINER }
      let_it_be(:parent_key) { :group }

      it_behaves_like 'assigns is_source_accessible_to_current_user'

      def create_link(shared, invited)
        create(:project_group_link, project: shared, group: invited)
      end
    end

    context 'for group members' do
      let_it_be(:source_type) { 'group' }
      let_it_be(:admin_member_access) { Gitlab::Access::OWNER }
      let_it_be(:parent_key) { :parent }

      it_behaves_like 'assigns is_source_accessible_to_current_user'

      def create_link(shared, invited)
        create(:group_group_link, shared_group: shared, shared_with_group: invited)
      end
    end
  end
end
