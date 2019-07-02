# frozen_string_literal: true

require 'spec_helper'

describe 'getting projects', :nested_groups do
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
      projects(includeSubgroups: #{include_subgroups}) {
        edges {
          node {
            #{all_graphql_fields_for('Project')}
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

    context 'with no user' do
      it 'finds only public projects' do
        post_graphql(query, current_user: nil)

        expect(graphql_data['namespace']).to be_nil
      end
    end
  end

  it_behaves_like 'a graphql namespace'

  context 'when the namespace is a user' do
    subject { user.namespace }
    let(:include_subgroups) { false }

    it_behaves_like 'a graphql namespace'
  end

  context 'when not including subgroups' do
    let(:include_subgroups) { false }

    it_behaves_like 'a graphql namespace'
  end
end
