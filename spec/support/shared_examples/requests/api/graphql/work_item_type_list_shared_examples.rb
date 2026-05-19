# frozen_string_literal: true

RSpec.shared_examples 'graphql work item type list request spec' do |context_name = nil|
  include GraphqlHelpers

  include_context context_name || 'with work item types request context'

  let(:parent_key) { parent.to_ability_name.to_sym }
  let(:query) do
    graphql_query_for(
      parent_key.to_s,
      { 'fullPath' => parent.full_path },
      query_nodes('WorkItemTypes', work_item_type_fields)
    )
  end

  context 'when user has access to the resource parent' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query that returns data'

    it 'returns system-defined work item types' do
      returned_types = graphql_data_at(parent_key, :workItemTypes, :nodes)
      type_names = returned_types.pluck('name')
      provider = ::WorkItems::TypesFramework::Provider.new(parent)

      system_type_names = provider.available_types.map(&:name)
      expect(type_names).to all(be_in(system_type_names))

      expect(returned_types.size).to eq(provider.available_types.count)
    end

    it 'prevents N+1 queries' do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_graphql(query, current_user: current_user) }
      expect(graphql_errors).to be_blank

      # Work item types are now in-memory (SystemDefined::Type), so the query
      # count should remain stable regardless of the number of types.
      expect do
        post_graphql(query, current_user: current_user)
      end.to issue_same_number_of_queries_as(control)
      expect(graphql_errors).to be_blank
    end

    context 'when filtering by name' do
      let(:query) do
        <<~QUERY
          query {
            #{parent_key}(fullPath: "#{parent.full_path}") {
              workItemTypes(name: ISSUE) {
                nodes {
                  #{work_item_type_fields}
                }
              }
            }
          }
        QUERY
      end

      it_behaves_like 'a working graphql query that returns data'
    end

    context 'when filtering with only_available' do
      let(:query) do
        <<~QUERY
          query {
            #{parent_key}(fullPath: "#{parent.full_path}") {
              workItemTypes(onlyAvailable: true) {
                nodes {
                  #{work_item_type_fields}
                }
              }
            }
          }
        QUERY
      end

      it_behaves_like 'a working graphql query that returns data'
    end
  end

  context "when user doesn't have access to the parent" do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'does not return the parent' do
      expect(graphql_data).to eq(parent_key.to_s => nil)
    end
  end

  describe 'enabled field' do
    let(:work_item_type_fields) { 'name enabled' }

    it 'returns enabled: false for non-group types (like Issue) in group context' do
      skip 'Only applicable to group namespaces' unless parent.is_a?(Group)

      post_graphql(query, current_user: current_user)

      returned_types = graphql_data_at(parent_key, :workItemTypes, :nodes)
      issue_data = returned_types.find { |t| t['name'] == 'Issue' }
      expect(issue_data['enabled']).to be(false)
    end

    it 'returns enabled: true for non-group types (like Issue) in project context' do
      skip 'Only applicable to project namespaces' unless parent.is_a?(Project)

      post_graphql(query, current_user: current_user)

      returned_types = graphql_data_at(parent_key, :workItemTypes, :nodes)
      issue_data = returned_types.find { |t| t['name'] == 'Issue' }
      expect(issue_data['enabled']).to be(true)
    end
  end

  def ids_from_response
    graphql_data_at(parent_key, :workItemTypes, :nodes, :id).map { |gid| GlobalID.new(gid).model_id.to_i }
  end
end
