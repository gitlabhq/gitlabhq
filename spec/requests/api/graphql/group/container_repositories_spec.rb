# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting container repositories in a group', feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:container_repository) { create(:container_repository, project: project) }
  let_it_be(:container_repositories_delete_scheduled) { create_list(:container_repository, 2, :status_delete_scheduled, project: project) }
  let_it_be(:container_repositories_delete_failed) { create_list(:container_repository, 2, :status_delete_failed, project: project) }
  let_it_be(:container_repositories) { [container_repository, container_repositories_delete_scheduled, container_repositories_delete_failed].flatten }
  let_it_be(:container_expiration_policy) { project.container_expiration_policy }

  let(:excluded_fields) { %w[pipeline jobs productAnalyticsState mlModels mergeTrains mlExperiments] }
  let(:container_repositories_fields) do
    <<~GQL
      edges {
        node {
          #{all_graphql_fields_for('container_repositories'.classify, excluded: excluded_fields)}
        }
      }
    GQL
  end

  let(:fields) do
    <<~GQL
      #{query_graphql_field('container_repositories', {}, container_repositories_fields)}
      containerRepositoriesCount
    GQL
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      fields
    )
  end

  let(:user) { owner }
  let(:variables) { {} }
  let(:container_repositories_response) { graphql_data.dig('group', 'containerRepositories', 'edges') }
  let(:container_repositories_count_response) { graphql_data.dig('group', 'containerRepositoriesCount') }

  before do
    group.add_owner(owner)
    stub_container_registry_config(enabled: true)
    container_repositories.each do |repository|
      stub_container_registry_tags(repository: repository.path, tags: %w[tag1 tag2 tag3], with_manifest: false)
    end
  end

  subject { post_graphql(query, current_user: user, variables: variables) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end
  end

  context 'with different permissions' do
    let_it_be(:user) { create(:user) }

    where(:group_visibility, :role, :access_granted, :destroy_container_repository) do
      :private | :maintainer | true   | true
      :private | :developer  | true   | true
      :private | :reporter   | true   | false
      :private | :guest      | false  | false
      :private | :anonymous  | false  | false
      :public  | :maintainer | true   | true
      :public  | :developer  | true   | true
      :public  | :reporter   | true   | false
      :public  | :guest      | false  | false
      :public  | :anonymous  | false  | false
    end

    with_them do
      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility.to_s.upcase, false))
        project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility.to_s.upcase, false))

        group.add_member(user, role) unless role == :anonymous
      end

      it 'return the proper response' do
        subject

        if access_granted
          expect(container_repositories_response.size).to eq(container_repositories.size)
          container_repositories_response.each do |repository_response|
            expect(repository_response.dig('node', 'userPermissions', 'destroyContainerRepository')).to eq(destroy_container_repository)
          end
        else
          expect(container_repositories_response).to eq(nil)
        end
      end
    end
  end

  context 'limiting the number of repositories' do
    let(:limit) { 1 }
    let(:variables) do
      { path: group.full_path, n: limit }
    end

    let(:query) do
      <<~GQL
        query($path: ID!, $n: Int) {
          group(fullPath: $path) {
            containerRepositories(first: $n) { #{container_repositories_fields} }
          }
        }
      GQL
    end

    it 'only returns N repositories' do
      subject

      expect(container_repositories_response.size).to eq(limit)
    end
  end

  context 'filter by name' do
    let_it_be(:container_repository) { create(:container_repository, name: 'fooBar', project: project) }

    let(:name) { 'ooba' }
    let(:query) do
      <<~GQL
        query($path: ID!, $name: String) {
          group(fullPath: $path) {
            containerRepositories(name: $name) { #{container_repositories_fields} }
          }
        }
      GQL
    end

    let(:variables) do
      { path: group.full_path, name: name }
    end

    before do
      stub_container_registry_tags(repository: container_repository.path, tags: %w[tag4 tag5 tag6], with_manifest: false)
    end

    it 'returns the searched container repository' do
      subject

      expect(container_repositories_response.size).to eq(1)
      expect(container_repositories_response.first.dig('node', 'id')).to eq(container_repository.to_global_id.to_s)
    end
  end

  it_behaves_like 'handling graphql network errors with the container registry'

  it_behaves_like 'not hitting graphql network errors with the container registry' do
    let(:excluded_fields) { %w[pipeline jobs tags tagsCount productAnalyticsState mlModels mergeTrains mlExperiments] }
  end

  it 'returns the total count of container repositories' do
    subject

    expect(container_repositories_count_response).to eq(container_repositories.size)
  end

  describe 'protectionRuleExists' do
    let_it_be(:container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project, repository_path_pattern: container_repository.path)
    end

    let_it_be(:project_2) { create(:project, :private, group: group) }
    let_it_be(:container_repository_2) { create(:container_repository, project: project_2) }
    let_it_be(:container_registry_protection_rule_2) do
      create(:container_registry_protection_rule, project: project_2, repository_path_pattern: container_repository_2.path)
    end

    let_it_be(:project_3) { create(:project, :private, group: group) }
    let_it_be(:container_repository_3) { create(:container_repository, project: project_3) }
    let_it_be(:container_registry_protection_rule_3) do
      create(:container_registry_protection_rule, project: project_3, repository_path_pattern: container_repository_3.path)
    end

    before do
      stub_container_registry_tags(repository: container_repository_2.path, tags: %w[tag1 tag2 tag3], with_manifest: false)
      stub_container_registry_tags(repository: container_repository_3.path, tags: %w[tag1 tag2 tag3], with_manifest: false)
    end

    it 'returns true for protected container respositories' do
      subject

      expect(container_repositories_response.count).to eq 7

      expect(find_container_repositories_response(container_repository.path).dig('node', 'protectionRuleExists')).to be true
      expect(find_container_repositories_response(container_repository_2.path).dig('node', 'protectionRuleExists')).to be true
      expect(find_container_repositories_response(container_repository_3.path).dig('node', 'protectionRuleExists')).to be true
      [*container_repositories_delete_scheduled, *container_repositories_delete_failed].each do |repository|
        expect(find_container_repositories_response(repository.path).dig('node', 'protectionRuleExists')).to be false
      end
    end

    it 'executes only one database queries for all projects' do
      expect { subject }.to match_query_count(1).for_model(::ContainerRegistry::Protection::Rule)
    end

    context 'when 25 container repositories belong to group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:projects) { create_list(:project, 5, :private, group: group) }

      before_all do
        projects.each do |project|
          container_repositories = create_list(:container_repository, 5, project: project)
          create(:container_registry_protection_rule, project: project,
            repository_path_pattern: container_repositories.first.path)
        end
      end

      before do
        group.container_repositories.each do |container_repository|
          stub_container_registry_tags(repository: container_repository.path, tags: %w[tag1 tag2 tag3], with_manifest: false)
        end
      end

      it 'executes only two database queries to check the protection rules for container repositories in batches of 20' do
        expect { subject }.to match_query_count(2).for_model(::ContainerRegistry::Protection::Rule)
      end
    end

    def find_container_repositories_response(container_repository_path)
      container_repositories_response.find { |res| res.dig('node', 'path') == container_repository_path }
    end
  end
end
