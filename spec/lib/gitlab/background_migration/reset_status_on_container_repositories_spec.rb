# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories, feature_category: :container_registry do
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:container_repositories_table) { table(:container_repositories) }
  let(:routes_table) { table(:routes) }

  let!(:root_group) do
    namespaces_table.create!(name: 'root_group', path: 'root_group', type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [new_group.id])
    end
  end

  let!(:group1) do
    namespaces_table.create!(name: 'group1', path: 'group1', parent_id: root_group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, new_group.id])
    end
  end

  let!(:subgroup1) do
    namespaces_table.create!(name: 'subgroup1', path: 'subgroup1', parent_id: group1.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, group1.id, new_group.id])
    end
  end

  let!(:group2) do
    namespaces_table.create!(name: 'group2', path: 'group2', parent_id: root_group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, new_group.id])
    end
  end

  let!(:group1_project_namespace) do
    namespaces_table.create!(name: 'group1_project', path: 'group1_project', type: 'Project', parent_id: group1.id)
  end

  let!(:subgroup1_project_namespace) do
    namespaces_table.create!(
      name: 'subgroup1_project',
      path: 'subgroup1_project',
      type: 'Project',
      parent_id: subgroup1.id
    )
  end

  let!(:group2_project_namespace) do
    namespaces_table.create!(
      name: 'group2_project',
      path: 'group2_project',
      type: 'Project',
      parent_id: group2.id
    )
  end

  let!(:group1_project) do
    projects_table.create!(
      name: 'group1_project',
      path: 'group1_project',
      namespace_id: group1.id,
      project_namespace_id: group1_project_namespace.id
    )
  end

  let!(:subgroup1_project) do
    projects_table.create!(
      name: 'subgroup1_project',
      path: 'subgroup1_project',
      namespace_id: subgroup1.id,
      project_namespace_id: subgroup1_project_namespace.id
    )
  end

  let!(:group2_project) do
    projects_table.create!(
      name: 'group2_project',
      path: 'group2_project',
      namespace_id: group2.id,
      project_namespace_id: group2_project_namespace.id
    )
  end

  let!(:route2) do
    routes_table.create!(
      source_id: group2_project.id,
      source_type: 'Project',
      path: 'root_group/group2/group2_project',
      namespace_id: group2_project_namespace.id
    )
  end

  let!(:delete_scheduled_container_repository1) do
    container_repositories_table.create!(project_id: group1_project.id, status: 0, name: 'container_repository1')
  end

  let!(:delete_scheduled_container_repository2) do
    container_repositories_table.create!(project_id: subgroup1_project.id, status: 0, name: 'container_repository2')
  end

  let!(:delete_scheduled_container_repository3) do
    container_repositories_table.create!(project_id: group2_project.id, status: 0, name: 'container_repository3')
  end

  let!(:delete_ongoing_container_repository4) do
    container_repositories_table.create!(project_id: group2_project.id, status: 2, name: 'container_repository4')
  end

  let(:migration) do
    described_class.new(
      start_id: container_repositories_table.minimum(:id),
      end_id: container_repositories_table.maximum(:id),
      batch_table: :container_repositories,
      batch_column: :id,
      sub_batch_size: 50,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#filter_batch' do
    it 'scopes the relation to delete scheduled container repositories' do
      expected = container_repositories_table.where(status: 0).pluck(:id)
      actual = migration.filter_batch(container_repositories_table).pluck(:id)

      expect(actual).to match_array(expected)
    end
  end

  describe '#perform' do
    let(:registry_api_url) { 'http://example.com' }

    subject(:perform) { migration.perform }

    before do
      stub_container_registry_config(
        enabled: true,
        api_url: registry_api_url,
        key: 'spec/fixtures/x509_certificate_pk.key'
      )
      stub_tags_list(path: 'root_group/group1/group1_project/container_repository1')
      stub_tags_list(path: 'root_group/group1/subgroup1/subgroup1_project/container_repository2', tags: [])
      stub_tags_list(path: 'root_group/group2/group2_project/container_repository3')
    end

    shared_examples 'resetting status of all container repositories scheduled for deletion' do
      it 'resets all statuses' do
        expect_logging_on(
          path: 'root_group/group1/group1_project/container_repository1',
          id: delete_scheduled_container_repository1.id,
          has_tags: true
        )
        expect_logging_on(
          path: 'root_group/group1/subgroup1/subgroup1_project/container_repository2',
          id: delete_scheduled_container_repository2.id,
          has_tags: true
        )
        expect_logging_on(
          path: 'root_group/group2/group2_project/container_repository3',
          id: delete_scheduled_container_repository3.id,
          has_tags: true
        )

        expect { perform }
          .to change { delete_scheduled_container_repository1.reload.status }.from(0).to(nil)
          .and change { delete_scheduled_container_repository3.reload.status }.from(0).to(nil)
          .and change { delete_scheduled_container_repository2.reload.status }.from(0).to(nil)
      end
    end

    it 'resets status of container repositories with tags' do
      expect_pull_access_token_on(path: 'root_group/group1/group1_project/container_repository1')
      expect_pull_access_token_on(path: 'root_group/group1/subgroup1/subgroup1_project/container_repository2')
      expect_pull_access_token_on(path: 'root_group/group2/group2_project/container_repository3')

      expect_logging_on(
        path: 'root_group/group1/group1_project/container_repository1',
        id: delete_scheduled_container_repository1.id,
        has_tags: true
      )
      expect_logging_on(
        path: 'root_group/group1/subgroup1/subgroup1_project/container_repository2',
        id: delete_scheduled_container_repository2.id,
        has_tags: false
      )
      expect_logging_on(
        path: 'root_group/group2/group2_project/container_repository3',
        id: delete_scheduled_container_repository3.id,
        has_tags: true
      )

      expect { perform }
        .to change { delete_scheduled_container_repository1.reload.status }.from(0).to(nil)
        .and change { delete_scheduled_container_repository3.reload.status }.from(0).to(nil)
        .and not_change { delete_scheduled_container_repository2.reload.status }
    end

    context 'with the registry disabled' do
      before do
        allow(::Gitlab.config.registry).to receive(:enabled).and_return(false)
      end

      it_behaves_like 'resetting status of all container repositories scheduled for deletion'
    end

    context 'with the registry api url not defined' do
      before do
        allow(::Gitlab.config.registry).to receive(:api_url).and_return('')
      end

      it_behaves_like 'resetting status of all container repositories scheduled for deletion'
    end

    context 'with a faraday error' do
      before do
        client_double = instance_double('::ContainerRegistry::Client')
        allow(::ContainerRegistry::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:repository_tags).and_raise(Faraday::TimeoutError)

        expect_pull_access_token_on(path: 'root_group/group1/group1_project/container_repository1')
        expect_pull_access_token_on(path: 'root_group/group1/subgroup1/subgroup1_project/container_repository2')
        expect_pull_access_token_on(path: 'root_group/group2/group2_project/container_repository3')
      end

      it_behaves_like 'resetting status of all container repositories scheduled for deletion'
    end

    def stub_tags_list(path:, tags: %w[tag1])
      url = "#{registry_api_url}/v2/#{path}/tags/list?n=1"

      stub_request(:get, url)
        .with(
          headers: {
            'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', '),
            'Authorization' => /bearer .+/,
            'User-Agent' => "GitLab/#{Gitlab::VERSION}"
          }
        )
        .to_return(
          status: 200,
          body: Gitlab::Json.dump(tags: tags),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def expect_pull_access_token_on(path:)
      expect(Auth::ContainerRegistryAuthenticationService)
          .to receive(:pull_access_token).with(path).and_call_original
    end

    def expect_logging_on(path:, id:, has_tags:)
      expect(::Gitlab::BackgroundMigration::Logger)
        .to receive(:info).with(
          migrator: described_class::MIGRATOR,
          has_tags: has_tags,
          container_repository_id: id,
          container_repository_path: path
        )
    end
  end
end
