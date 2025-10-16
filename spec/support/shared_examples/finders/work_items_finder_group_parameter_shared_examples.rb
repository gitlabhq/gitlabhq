# frozen_string_literal: true

RSpec.shared_examples 'work items finder group parameter' do |expect_group_items: true|
  context 'when group parameter is present' do
    let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group, author: user) }
    let_it_be(:group_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: group, author: user2)
    end

    let_it_be(:subgroup_work_item) { create(:work_item, :group_level, namespace: subgroup, author: user) }
    let_it_be(:subgroup_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: subgroup, author: user2)
    end

    let_it_be(:subgroup2) { create(:group, :private, parent: group) }
    let_it_be(:subgroup2_work_item) { create(:work_item, :group_level, namespace: subgroup2, author: user) }
    let_it_be(:subgroup2_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: subgroup2, author: user2)
    end

    let(:params) { { group_id: group } }
    let(:scope) { 'all' }

    it 'returns group level work items' do
      if expect_group_items
        expect(items).to contain_exactly(group_work_item)
      else
        expect(items).to be_empty
      end
    end

    context 'when user has access to confidential items' do
      before do
        group.add_reporter(user)
      end

      it 'includes confidential group-level items' do
        if expect_group_items
          expect(items).to contain_exactly(group_work_item, group_confidential_work_item)
        else
          expect(items).to be_empty
        end
      end
    end

    context 'with use_namespace_traversal_ids_for_work_items_finder feature flag disabled' do
      let_it_be(:group_project) { create(:project, group: group) }
      let_it_be(:group_project_work_item) { create(:work_item, author: user, project: group_project) }

      before do
        stub_feature_flags(use_namespace_traversal_ids_for_work_items_finder: false)
      end

      it 'returns only group level work items' do
        if expect_group_items
          expect(items).to contain_exactly(group_work_item)
        else
          expect(items).to be_empty
        end
      end

      context 'when include_descendants is true and user can access all subgroups' do
        before do
          params[:include_descendants] = true
          group.add_reporter(user)
        end

        it 'returns work_items in the group hierarchy' do
          if expect_group_items
            expect(items).to contain_exactly(
              group_work_item,
              group_project_work_item,
              group_confidential_work_item,
              subgroup_work_item,
              subgroup_confidential_work_item,
              subgroup2_work_item,
              subgroup2_confidential_work_item,
              item1,
              item4,
              item5
            )
          else
            expect(items).to contain_exactly(item1, item4, item5, group_project_work_item)
          end
        end
      end
    end

    context 'when include_descendants is true' do
      before do
        params[:include_descendants] = true
      end

      context 'when user does not have access to all subgroups' do
        it 'includes work items from subgroups and child projects with access' do
          if expect_group_items
            expect(items).to contain_exactly(group_work_item, subgroup_work_item, item1, item4, item5)
          else
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'when user has read access to all subgroups' do
        before_all do
          subgroup2.add_guest(user)
        end

        it 'includes work items from subgroups and child projects with access' do
          if expect_group_items
            expect(items).to contain_exactly(
              group_work_item,
              subgroup_work_item,
              subgroup2_work_item,
              item1,
              item4,
              item5
            )
          else
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end

        context 'when exclude_group_work_items is true' do
          before do
            params[:exclude_group_work_items] = true
          end

          it 'excludes group-level work items' do
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'when user can access all confidential items' do
        before_all do
          group.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects' do
          if expect_group_items
            expect(items).to contain_exactly(
              group_work_item,
              group_confidential_work_item,
              subgroup_work_item,
              subgroup_confidential_work_item,
              subgroup2_work_item,
              subgroup2_confidential_work_item,
              item1,
              item4,
              item5
            )
          else
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'when user can access confidential issues of certain subgroups only' do
        before_all do
          subgroup2.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects with access' do
          if expect_group_items
            expect(items).to contain_exactly(
              group_work_item,
              subgroup_work_item,
              subgroup2_work_item,
              subgroup2_confidential_work_item,
              item1,
              item4,
              item5
            )
          else
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'when exclude_projects is true' do
        before do
          params[:exclude_projects] = true
        end

        it 'does not include work items from projects' do
          if expect_group_items
            expect(items).to contain_exactly(group_work_item, subgroup_work_item)
          else
            expect(items).to be_empty
          end
        end

        context 'when exclude_group_work_items is true' do
          before do
            params[:exclude_group_work_items] = true
          end

          it 'excludes group-level work items' do
            expect(items).to be_empty
          end
        end
      end
    end

    context 'when include_ancestors is true' do
      let(:params) { { group_id: subgroup, include_ancestors: true } }

      it 'includes work items from ancestor groups' do
        if expect_group_items
          expect(items).to contain_exactly(group_work_item, subgroup_work_item)
        else
          expect(items).to be_empty
        end
      end
    end

    context 'when both include_descendants and include_ancestors are true' do
      let_it_be(:sub_subgroup) { create(:group, parent: subgroup) }
      let_it_be(:sub_subgroup_work_item) { create(:work_item, :group_level, namespace: sub_subgroup, author: user) }

      let(:params) { { group_id: subgroup, include_descendants: true, include_ancestors: true } }

      it 'includes work items from ancestor groups, subgroups, and child projects' do
        if expect_group_items
          expect(items).to contain_exactly(group_work_item, subgroup_work_item, sub_subgroup_work_item, item4)
        else
          expect(items).to contain_exactly(item4)
        end
      end

      context 'when exclude_group_work_items is true' do
        let(:params) do
          { group_id: subgroup, exclude_group_work_items: true, include_ancestors: true, include_descendants: true }
        end

        it 'return project-level items only' do
          expect(items).to contain_exactly(item4)
        end
      end
    end
  end
end
