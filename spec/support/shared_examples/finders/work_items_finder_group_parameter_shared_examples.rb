# frozen_string_literal: true

RSpec.shared_examples 'work items finder group parameter' do
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

    before do
      stub_licensed_features(epics: true)
    end

    context 'when namespace_level_work_items and work_item_epics is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false, work_item_epics: false)
      end

      it 'does not return group level work items' do
        expect(items).to contain_exactly(item1, item5)
      end
    end

    context 'when work_item_epics is disabled' do
      before do
        stub_feature_flags(work_item_epics: false)
      end

      it 'returns group level work items' do
        expect(items).to contain_exactly(group_work_item)
      end
    end

    it 'returns group level work items' do
      expect(items).to contain_exactly(group_work_item)
    end

    context 'when user has access to confidential items' do
      before do
        group.add_reporter(user)
      end

      it 'includes confidential group-level items' do
        expect(items).to contain_exactly(group_work_item, group_confidential_work_item)
      end
    end

    context 'when include_descendants is true' do
      before do
        params[:include_descendants] = true
      end

      context 'when user does not have access to all subgroups' do
        it 'includes work items from subgroups and child projects with access' do
          expect(items).to contain_exactly(group_work_item, subgroup_work_item, item1, item4, item5)
        end
      end

      context 'when user has read access to all subgroups' do
        before_all do
          subgroup2.add_guest(user)
        end

        it 'includes work items from subgroups and child projects with access' do
          expect(items).to contain_exactly(
            group_work_item,
            subgroup_work_item,
            subgroup2_work_item,
            item1,
            item4,
            item5
          )
        end
      end

      context 'when user can access all confidential items' do
        before_all do
          group.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects' do
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
        end
      end

      context 'when user can access confidential issues of certain subgroups only' do
        before_all do
          subgroup2.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects with access' do
          expect(items).to contain_exactly(
            group_work_item,
            subgroup_work_item,
            subgroup2_work_item,
            subgroup2_confidential_work_item,
            item1,
            item4,
            item5
          )
        end
      end

      context 'when exclude_projects is true' do
        before do
          params[:exclude_projects] = true
        end

        it 'does not include work items from projects' do
          expect(items).to contain_exactly(group_work_item, subgroup_work_item)
        end
      end
    end

    context 'when include_ancestors is true' do
      let(:params) { { group_id: subgroup, include_ancestors: true } }

      it 'includes work items from ancestor groups' do
        expect(items).to contain_exactly(group_work_item, subgroup_work_item)
      end
    end

    context 'when both include_descendants and include_ancestors are true' do
      let_it_be(:sub_subgroup) { create(:group, parent: subgroup) }
      let_it_be(:sub_subgroup_work_item) { create(:work_item, :group_level, namespace: sub_subgroup, author: user) }

      let(:params) { { group_id: subgroup, include_descendants: true, include_ancestors: true } }

      it 'includes work items from ancestor groups, subgroups, and child projects' do
        expect(items).to contain_exactly(group_work_item, subgroup_work_item, sub_subgroup_work_item, item4)
      end
    end
  end
end
