# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting projects', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let(:group)             { create(:group) }
  let!(:project)          { create(:project, namespace: subject) }
  let(:nested_group)      { create(:group, parent: group) }
  let!(:nested_project)   { create(:project, group: nested_group) }
  let!(:public_project)   { create(:project, :public, namespace: subject) }
  let(:user)              { create(:user) }
  let(:include_subgroups) { true }

  subject { group }

  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => subject.full_path },
      <<~QUERY
      id
      projects(includeSubgroups: #{include_subgroups}) {
        edges {
          node {
            #{all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState'])}
          }
        }
      }
      QUERY
    )
  end

  before do
    group.add_owner(user)
  end

  shared_examples 'a graphql namespace' do
    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    it "includes the packages size if the user can read the statistics" do
      post_graphql(query, current_user: user)

      count = if include_subgroups
                subject.all_projects.count
              else
                subject.projects.count
              end

      expect(graphql_data['namespace']['projects']['edges'].size).to eq(count)
    end
  end

  it_behaves_like 'a graphql namespace'

  context 'when no user is given' do
    it 'finds only public projects' do
      post_graphql(query, current_user: nil)

      expect(graphql_data_at(:namespace, :projects, :edges).size).to eq(1)
    end
  end

  context 'when the namespace is a user' do
    subject { user.namespace }

    let(:include_subgroups) { false }

    it_behaves_like 'a graphql namespace'

    it 'does not show namespace entity for anonymous user' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['namespace']).to be_nil
    end
  end

  context 'when not including subgroups' do
    let(:include_subgroups) { false }

    it_behaves_like 'a graphql namespace'
  end

  describe 'sorting and pagination' do
    let_it_be(:ns) { create(:group) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project_1) { create(:project, name: 'Project', path: 'project', namespace: ns) }
    let_it_be(:project_2) { create(:project, name: 'Test Project', path: 'test-project', namespace: ns) }
    let_it_be(:project_3) { create(:project, name: 'Test', path: 'test', namespace: ns) }
    let_it_be(:project_4) { create(:project, name: 'Test Project Other', path: 'other-test-project', namespace: ns) }

    let(:data_path) { [:namespace, :projects] }

    let(:ns_args) { { full_path: ns.full_path } }
    let(:search) { 'test' }

    before do
      ns.add_owner(current_user)
    end

    def pagination_query(params)
      arguments = params.merge(include_subgroups: include_subgroups, search: search)
      graphql_query_for(:namespace, ns_args, query_graphql_field(:projects, arguments, <<~GQL))
        #{page_info}
        nodes { name }
      GQL
    end

    context 'when sorting by similarity' do
      it_behaves_like 'sorted paginated query' do
        let(:node_path) { %w[name] }
        let(:sort_param) { :SIMILARITY }
        let(:first_param) { 2 }
        let(:all_records) { [project_3.name, project_2.name, project_4.name] }
      end
    end
  end
end
