# frozen_string_literal: true

RSpec.shared_examples 'groups query' do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:public_group) { create(:group, :public, name: 'Group A') }
  let_it_be(:private_group) { create(:group, :private, name: 'Group B') }
  let(:current_user) { user }

  let_it_be(:field_name) { :groups }
  let(:filters) { {} }

  let(:group_fields) { all_graphql_fields_for('Group', excluded: %w[runners ciQueueingHistory securityCategories]) }
  let(:fields) do
    <<~FIELDS
      nodes {
        #{group_fields}
      }
      count
    FIELDS
  end

  let(:query) do
    graphql_query_for(field_name, filters, fields)
  end

  subject { post_graphql(query, current_user: user) }

  def groups_graphql_data(path = [:nodes])
    graphql_data_at(field_name.to_s.camelize(:lower).to_sym, *path)
  end

  it 'is countable' do
    subject

    expect(groups_graphql_data([:count])).to eq(1)
  end

  describe "Query groups(search)" do
    let(:groups) { groups_graphql_data }
    let(:names) { groups.pluck('name') }

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end
    end

    it 'includes public groups' do
      subject

      expect(names).to eq([public_group.name])
    end

    it 'includes accessible private groups ordered by name' do
      private_group.add_maintainer(user)

      subject

      expect(names).to eq([public_group.name, private_group.name])
    end

    context 'with `search` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }
      let(:filters) { { search: 'oth' } }

      it 'filters groups by name' do
        subject

        expect(names).to contain_exactly(other_group.name)
      end
    end

    context 'with `owned_only` argument' do
      let_it_be(:owned_group) { create(:group, name: 'with owner role', owners: user) }
      let(:filters) { { ownedOnly: true } }

      it 'return only owned groups' do
        subject

        expect(names).to contain_exactly(owned_group.name)
      end
    end
  end

  describe 'active argument' do
    let_it_be(:group_pending_deletion) { create(:group_with_deletion_schedule, owners: user) }

    context 'when active argument is nil' do
      it 'returns all groups' do
        subject

        expect(groups_graphql_data).to match_array([a_graphql_entity_for(public_group),
          a_graphql_entity_for(group_pending_deletion)])
      end
    end

    context 'when active argument is true' do
      let(:filters) { { active: true } }

      it 'returns only groups that are not pending deletion' do
        subject

        expect(groups_graphql_data).to match_array([a_graphql_entity_for(public_group)])
      end
    end

    context 'when active argument is false' do
      let(:filters) { { active: false } }

      it 'returns only groups that are pending deletion' do
        subject

        expect(groups_graphql_data).to match_array([a_graphql_entity_for(group_pending_deletion)])
      end
    end
  end

  describe 'group sorting' do
    let_it_be(:public_group2) { create(:group, :public, name: 'Group C') }
    let_it_be(:public_group3) { create(:group, :public, name: 'Group D') }
    let_it_be(:all_groups) { [public_group, public_group2, public_group3] }
    let_it_be(:first_param) { 2 }
    let_it_be(:data_path) { [field_name] }

    where(:field, :direction, :sorted_groups) do
      'id'   | 'asc'  | lazy { all_groups.sort_by(&:id) }
      'id'   | 'desc' | lazy { all_groups.sort_by(&:id).reverse }
      'name' | 'asc'  | lazy { all_groups.sort_by(&:name) }
      'name' | 'desc' | lazy { all_groups.sort_by(&:name).reverse }
      'path' | 'asc'  | lazy { all_groups.sort_by(&:path) }
      'path' | 'desc' | lazy { all_groups.sort_by(&:path).reverse }
    end

    with_them do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { "#{field}_#{direction}" }
        let(:all_records) { sorted_groups.map { |p| global_id_of(p).to_s } }
      end
    end

    context 'when sorting by storage size' do
      let_it_be(:public_group_project) do
        create(:project,
          namespace: public_group,
          statistics: build(:project_statistics, namespace: public_group, storage_size: 100.megabytes)
        )
      end

      let_it_be(:public_group2_project) do
        create(:project,
          namespace: public_group2,
          statistics: build(:project_statistics, namespace: public_group2, storage_size: 200.megabytes)
        )
      end

      let_it_be(:public_group3_project) do
        create(:project,
          namespace: public_group3,
          statistics: build(:project_statistics, namespace: public_group3, storage_size: 50.megabytes)
        )
      end

      let_it_be(:private_group_project) do
        create(:project,
          namespace: private_group,
          statistics: build(:project_statistics, namespace: private_group, storage_size: 300.megabytes)
        )
      end

      context 'when user is not admin' do
        # Sorting by ID in descending order is the fallback when the sort option is unrecognized.
        let_it_be(:fallback_sorted_records) { all_groups.sort_by(&:id).reverse.map { |p| global_id_of(p).to_s } }

        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { "storage_size_keyset_asc" }
          let(:all_records) { fallback_sorted_records }
        end

        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { "storage_size_keyset_desc" }
          let(:all_records) { fallback_sorted_records }
        end
      end

      context 'when user is admin', :enable_admin_mode do
        let_it_be(:admin) { create(:admin) }

        let(:current_user) { admin }

        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { "storage_size_keyset_desc" }
          let(:all_records) do
            [private_group, public_group2, public_group, public_group3].map { |p| global_id_of(p).to_s }
          end
        end

        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { "storage_size_keyset_asc" }
          let(:all_records) do
            [public_group3, public_group, public_group2, private_group].map { |p| global_id_of(p).to_s }
          end
        end
      end
    end

    def pagination_query(params)
      graphql_query_for(
        '', {},
        query_nodes(:groups, :id, include_pagination_info: true, args: params)
      )
    end
  end

  describe 'project statistics' do
    context 'when user can read statistics' do
      before_all do
        public_group.add_owner(user)
      end

      it 'returns project_statistics field' do
        subject

        expect(graphql_data_at(field_name.to_s.camelize(:lower).to_sym, :nodes, 0, :project_statistics)).to include({
          "buildArtifactsSize" => 0.0,
          "lfsObjectsSize" => 0.0,
          "packagesSize" => 0.0,
          "pipelineArtifactsSize" => 0.0,
          "repositorySize" => 0.0,
          "snippetsSize" => 0.0,
          "storageSize" => 0.0,
          "uploadsSize" => 0.0,
          "wikiSize" => 0.0
        })
      end
    end

    context 'when user does not have admin ability' do
      it 'returns project_statistics field as nil' do
        subject

        expect(graphql_data_at(field_name, :nodes, 0, :project_statistics)).to be_nil
      end
    end
  end
end
