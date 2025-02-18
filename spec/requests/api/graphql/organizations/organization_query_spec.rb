# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting organization information', feature_category: :cell do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let(:query) { graphql_query_for(:organization, { id: organization.to_global_id }, organization_fields) }
  let(:current_user) { user }
  let(:organization_fields) do
    <<~FIELDS
      id
      path
      groups {
        nodes {
          id
        }
      }
    FIELDS
  end

  let_it_be(:organization_owner) { create(:organization_owner) }
  let_it_be(:organization) { organization_owner.organization }
  let_it_be(:default_organization) { create(:organization, :default) }
  let_it_be(:user) { organization_owner.user }
  let_it_be(:project) { create(:project, organization: organization) { |p| p.add_developer(user) } }
  let_it_be(:other_group) do
    create(:group, name: 'other-group', organization: organization) { |g| g.add_developer(user) }
  end

  let_it_be(:organization_group) { create(:group, organization: organization) }

  subject(:request_organization) { post_graphql(query, current_user: current_user) }

  context 'when the user does not have access to the organization' do
    let(:current_user) { create(:user) }

    context 'when organization is private' do
      let_it_be(:organization) { create(:organization, :private) }

      it 'returns no organization' do
        request_organization

        expect(graphql_data_at(:organization, :id)).to be_nil
      end
    end

    context 'when organization is public' do
      it 'only returns the public organization' do
        request_organization

        expect(graphql_data_at(:organization, :id)).to eq(organization.to_global_id.to_s)
      end
    end
  end

  context 'when user has access to the organization' do
    it_behaves_like 'a working graphql query' do
      before do
        request_organization
      end
    end

    context 'when requesting organization user' do
      let(:organization_fields) do
        <<~FIELDS
          organizationUsers {
            nodes {
              accessLevel {
                integerValue
                stringValue
              }
              badges {
                text
                variant
              }
              id
              isLastOwner
              user {
                id
              }
            }
          }
        FIELDS
      end

      it 'returns correct organization user fields' do
        request_organization

        organization_user_nodes = graphql_data_at(:organization, :organizationUsers, :nodes)
        expected_attributes = {
          "accessLevel" => { "integerValue" => 50, "stringValue" => "OWNER" },
          "badges" => [{ "text" => "It's you!", "variant" => 'muted' }],
          "id" => organization_owner.to_global_id.to_s,
          "isLastOwner" => true,
          "user" => { "id" => user.to_global_id.to_s }
        }
        expect(organization_user_nodes).to include(expected_attributes)
      end

      it 'avoids N+1 queries for all the fields' do
        base_query_count = ActiveRecord::QueryRecorder.new { run_query }

        organization_user_2 = create(:organization_user, organization: organization)
        other_group.add_developer(organization_user_2.user)
        organization_user_from_project = create(:organization_user, organization: organization)
        project.add_developer(organization_user_from_project.user)

        expect { run_query }.not_to exceed_query_limit(base_query_count)
      end

      private

      def run_query
        run_with_clean_state(query, context: { current_user: current_user })
      end
    end

    context 'when requesting groups' do
      let(:groups) { graphql_data_at(:organization, :groups, :nodes) }
      let_it_be(:parent_group) { create(:group, name: 'parent-group', organization: organization) }
      let_it_be(:parent_group_global_id) { parent_group.to_global_id.to_s }
      let_it_be(:public_group) do
        create(:group, name: 'public-group', parent: parent_group, organization: organization)
      end

      let_it_be(:private_group) do
        create(:group, :private, name: 'private-group', organization: organization)
      end

      before_all do
        create(:group, :private, name: 'no-access', organization: organization)
        private_group.add_developer(user)
        public_group.add_developer(user)
        create(:group, organization: create(:organization)) { |g| g.add_developer(user) } # outside organization
      end

      it 'returns ancestors of authorized groups' do
        request_organization

        expect(groups.pluck('id')).to include(parent_group_global_id)
      end

      it 'returns all visible groups' do
        request_organization

        expected_groups = [parent_group, public_group, private_group, other_group, organization_group]
          .map { |group| group.to_global_id.to_s }
        expect(groups.pluck('id')).to match_array(expected_groups)
      end

      context 'with `search` argument' do
        let(:search) { 'oth' }
        let(:organization_fields) do
          <<~FIELDS
            id
            path
            groups(search: "#{search}") {
              nodes {
                id
                name
              }
            }
          FIELDS
        end

        it 'filters groups by name' do
          request_organization

          expect(groups).to contain_exactly(a_graphql_entity_for(other_group))
        end
      end

      describe 'group sorting' do
        let_it_be(:authorized_groups) { [parent_group, public_group, private_group, other_group, organization_group] }
        let_it_be(:first_param) { 2 }
        let_it_be(:data_path) { [:organization, :groups] }

        where(:field, :direction, :sorted_groups) do
          'id'   | 'asc'  | lazy { authorized_groups.sort_by(&:id) }
          'id'   | 'desc' | lazy { authorized_groups.sort_by(&:id).reverse }
          'name' | 'asc'  | lazy { authorized_groups.sort_by(&:name) }
          'name' | 'desc' | lazy { authorized_groups.sort_by(&:name).reverse }
          'path' | 'asc'  | lazy { authorized_groups.sort_by(&:path) }
          'path' | 'desc' | lazy { authorized_groups.sort_by(&:path).reverse }
        end

        with_them do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { "#{field}_#{direction}" }
            let(:all_records) { sorted_groups.map { |p| global_id_of(p).to_s } }
          end
        end

        def pagination_query(params)
          graphql_query_for(
            :organization, { id: organization.to_global_id },
            query_nodes(:groups, :id, include_pagination_info: true, args: params)
          )
        end
      end
    end

    context 'when requesting projects' do
      let(:projects) { graphql_data_at(:organization, :projects, :nodes) }
      let(:organization_fields) do
        <<~FIELDS
          projects {
            nodes {
              id
            }
          }
        FIELDS
      end

      before_all do
        # some other project that shouldn't show up in our results
        create(:project, organization: create(:organization)) { |p| p.add_developer(user) }
      end

      before do
        request_organization
      end

      it_behaves_like 'a working graphql query'

      it 'returns projects' do
        expect(projects).to contain_exactly(a_graphql_entity_for(project))
      end

      describe 'project searching' do
        let_it_be(:other_project) do
          create(:project, name: 'other-project', organization: organization) { |p| p.add_developer(user) }
        end

        let_it_be(:non_member_project) { create(:project, :public, organization: organization) }

        context 'with `search` argument' do
          let(:search) { 'other' }
          let(:organization_fields) do
            <<~FIELDS
              projects(search: "#{search}") {
                nodes {
                  id
                  name
                }
              }
            FIELDS
          end

          it 'filters projects by name' do
            request_organization

            expect(projects).to contain_exactly(a_graphql_entity_for(other_project))
          end
        end
      end

      describe 'project sorting' do
        let_it_be(:another_project) { create(:project, organization: organization) { |p| p.add_developer(user) } }
        let_it_be(:another_project2) { create(:project, organization: organization) { |p| p.add_developer(user) } }
        let_it_be(:all_projects) { [another_project2, another_project, project] }
        let_it_be(:first_param) { 2 }
        let_it_be(:data_path) { [:organization, :projects] }

        where(:field, :direction, :sorted_projects) do
          'id'   | 'asc'  | lazy { all_projects.sort_by(&:id) }
          'id'   | 'desc' | lazy { all_projects.sort_by(&:id).reverse }
          'name' | 'asc'  | lazy { all_projects.sort_by(&:name) }
          'name' | 'desc' | lazy { all_projects.sort_by(&:name).reverse }
          'path' | 'asc'  | lazy { all_projects.sort_by(&:path) }
          'path' | 'desc' | lazy { all_projects.sort_by(&:path).reverse }
        end

        with_them do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { "#{field}_#{direction}" }
            let(:all_records) { sorted_projects.map { |p| global_id_of(p).to_s } }
          end
        end
      end

      def pagination_query(params)
        graphql_query_for(
          :organization, { id: organization.to_global_id },
          query_nodes(:projects, :id, include_pagination_info: true, args: params)
        )
      end
    end
  end
end
