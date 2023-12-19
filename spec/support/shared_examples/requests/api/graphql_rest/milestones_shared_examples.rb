# frozen_string_literal: true

# Examples for both GraphQL and REST APIs
RSpec.shared_examples 'group milestones including ancestors and descendants' do
  context 'for group milestones' do
    let_it_be(:current_user) { create(:user) }

    context 'when including descendant milestones in a public group' do
      let_it_be(:group) { create(:group, :public) }

      let(:params) { { include_descendants: true } }

      it 'finds milestones only in accessible projects and groups' do
        accessible_group = create(:group, :private, parent: group)
        accessible_project = create(:project, group: accessible_group)
        accessible_group.add_developer(current_user)
        inaccessible_group = create(:group, :private, parent: group)
        inaccessible_project = create(:project, :private, group: group)
        milestone1 = create(:milestone, group: group)
        milestone2 = create(:milestone, group: accessible_group)
        milestone3 = create(:milestone, project: accessible_project)
        create(:milestone, group: inaccessible_group)
        create(:milestone, project: inaccessible_project)

        milestone_ids = query_group_milestone_ids(params)

        expect(milestone_ids).to match_array([milestone1, milestone2, milestone3].pluck(:id))
      end
    end

    describe 'include_descendants and include_ancestors' do
      let_it_be(:parent_group) { create(:group, :public) }
      let_it_be(:group) { create(:group, :public, parent: parent_group) }
      let_it_be(:accessible_group) { create(:group, :private, parent: group) }
      let_it_be(:accessible_project) { create(:project, group: accessible_group) }
      let_it_be(:inaccessible_group) { create(:group, :private, parent: group) }
      let_it_be(:inaccessible_project) { create(:project, :private, group: group) }
      let_it_be(:milestone1) { create(:milestone, group: group) }
      let_it_be(:milestone2) { create(:milestone, group: accessible_group) }
      let_it_be(:milestone3) { create(:milestone, project: accessible_project) }
      let_it_be(:milestone4) { create(:milestone, group: inaccessible_group) }
      let_it_be(:milestone5) { create(:milestone, project: inaccessible_project) }
      let_it_be(:milestone6) { create(:milestone, group: parent_group) }

      before_all do
        accessible_group.add_developer(current_user)
      end

      context 'when including neither ancestor nor descendant milestones in a public group' do
        let(:params) { {} }

        it 'finds milestones only in accessible projects and groups' do
          expect(query_group_milestone_ids(params)).to match_array([milestone1.id])
        end
      end

      context 'when including descendant milestones in a public group' do
        let(:params) { { include_descendants: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(query_group_milestone_ids(params)).to match_array([milestone1, milestone2, milestone3].pluck(:id))
        end
      end

      context 'when including ancestor milestones in a public group' do
        let(:params) { { include_ancestors: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(query_group_milestone_ids(params)).to match_array([milestone1, milestone6].pluck(:id))
        end
      end

      context 'when including both ancestor and descendant milestones in a public group' do
        let(:params) { { include_descendants: true, include_ancestors: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(query_group_milestone_ids(params))
            .to match_array([milestone1, milestone2, milestone3, milestone6].pluck(:id))
        end
      end
    end
  end
end
