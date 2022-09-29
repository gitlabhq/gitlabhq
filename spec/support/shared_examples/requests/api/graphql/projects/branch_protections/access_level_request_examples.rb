# frozen_string_literal: true

RSpec.shared_examples 'perform graphql requests for AccessLevel type objects' do |access_level_kind|
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:variables) { { path: project.full_path } }

  let(:fields) { all_graphql_fields_for("#{access_level_kind.to_s.classify}AccessLevel", max_depth: 2) }
  let(:access_levels) { protected_branch.public_send("#{access_level_kind}_access_levels") }
  let(:access_levels_count) { access_levels.size }
  let(:maintainer_access_level) { access_levels.for_role.first }
  let(:user_access_level) { access_levels.for_user.first }
  let(:group_access_level) { access_levels.for_group.first }
  let(:user_access_level_data) { access_levels_data.find { |data| data['user'].present? } }
  let(:group_access_level_data) { access_levels_data.find { |data| data['group'].present? } }
  let(:maintainer_access_level_data) { access_levels_data.find { |data| data['user'].blank? && data['group'].blank? } }
  let(:access_levels_data) do
    graphql_data_at('project',
                    'branchRules',
                    'nodes',
                    0,
                    'branchProtection',
                    "#{access_level_kind.to_s.camelize(:lower)}AccessLevels",
                    'nodes')
  end

  let(:query) do
    <<~GQL
    query($path: ID!) {
      project(fullPath: $path) {
        branchRules(first: 1) {
          nodes {
            branchProtection {
              #{access_level_kind.to_s.camelize(:lower)}AccessLevels {
                nodes {
                  #{fields}
                }
              }
            }
          }
        }
      }
    }
    GQL
  end

  describe 'requesting AccessLevel type objects as a guest user' do
    let_it_be(:protected_branch) { create(:protected_branch, project: project) }

    before do
      create(:project_member, :guest, user: current_user, source: project)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query'

    it "does not return any #{access_level_kind.to_s.classify}AccessLevel objects" do
      expect(access_levels_data).not_to be_present
    end
  end

  describe 'requesting AccessLevel type objects as a maintainer' do
    let_it_be(:protected_branch) do
      create(:protected_branch,
             "maintainers_can_#{access_level_kind}",
             "user_can_#{access_level_kind}",
             "group_can_#{access_level_kind}",
             project: project)
    end

    before do
      create(:project_member, :maintainer, user: current_user, source: project)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query'

    it "returns all #{access_level_kind} access level fields", :aggregate_failures do
      expect(access_levels_count).to eq(3),
        "Expected 3 #{access_level_kind.to_s.classify}AccessLevel records present, got #{access_levels_count}"
      expect(access_levels_data.size).to eq(access_levels_count)

      [:maintainer, :user, :group].each do |access_level_type|
        access_level_data = public_send("#{access_level_type}_access_level_data")
        access_level = public_send("#{access_level_type}_access_level")

        expect(access_level_data['accessLevel']).to eq(access_level.access_level)
        expect(access_level_data['accessLevelDescription']).to eq(access_level.humanize)

        case access_level_type
        when :user
          expect(access_level_data.dig('user', 'name')).to eq(access_level.user.name)
          expect(access_level_data.dig('group', 'name')).to be_nil
        when :group
          expect(access_level_data.dig('group', 'name')).to eq(access_level.group.name)
          expect(access_level_data.dig('user', 'name')).to be_nil
        else
          expect(access_level_data.dig('group', 'name')).to be_nil
          expect(access_level_data.dig('user', 'name')).to be_nil
        end
      end
    end
  end
end
