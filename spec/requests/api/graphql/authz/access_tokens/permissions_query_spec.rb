# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.accessTokenPermissions', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:target_permission) { ::Authz::PermissionGroups::Assignable.get(:update_wiki) }

  let(:resource) do
    resource_definition = {
      name: 'Wiki Resource',
      description: 'Pages that can be created, edited, and managed by team members'
    }
    ::Authz::PermissionGroups::Resource.new(resource_definition, 'source_file')
  end

  let(:category) do
    category_definition = { name: 'Wiki Category' }
    ::Authz::PermissionGroups::Category.new(category_definition, 'source_file')
  end

  let(:query) do
    <<~GQL
      query {
        accessTokenPermissions {
          name
          description
          action
          resource
          resourceName
          resourceDescription
          category
          categoryName
          boundaries
        }
      }
    GQL
  end

  let(:permissions_data) { graphql_data['accessTokenPermissions'] }

  before do
    allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return(
      target_permission.name => target_permission
    )

    allow(::Authz::PermissionGroups::Resource).to receive(:get)
      .with("#{target_permission.category}/#{target_permission.resource}").and_return(resource)

    allow(::Authz::PermissionGroups::Category).to receive(:get)
      .with(target_permission.category).and_return(category)
  end

  context 'when user is authenticated' do
    it 'returns expected fields' do
      post_graphql(query, current_user: current_user)

      expect(permissions_data).to eq([{
        'name' => 'update_wiki',
        'description' => 'Grants the ability to update wikis',
        'action' => 'update',
        'resource' => 'wiki',
        'resourceName' => 'Wiki Resource',
        'resourceDescription' => resource.definition[:description],
        'category' => 'wiki',
        'categoryName' => 'Wiki Category',
        'boundaries' => %w[GROUP PROJECT]
      }])
    end
  end

  context 'when a permission is deprecated' do
    let(:deprecated_permission) do
      ::Authz::PermissionGroups::Assignable.new(
        {
          name: 'deprecated_permission',
          description: 'A deprecated permission',
          permissions: %w[deprecated_action],
          boundaries: %w[project],
          deprecated: true
        },
        "#{::Authz::PermissionGroups::Assignable::BASE_PATH}/category/resource/deprecated.yml"
      )
    end

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return(
        target_permission.name => target_permission,
        deprecated_permission.name => deprecated_permission
      )
    end

    it 'excludes deprecated permissions from results' do
      post_graphql(query, current_user: current_user)

      permission_names = permissions_data.pluck('name')
      expect(permission_names).to include('update_wiki')
      expect(permission_names).not_to include('deprecated_permission')
    end
  end

  context 'when resource names differ only in letter case' do
    def build_assignable(category_dir, resource_dir, action)
      ::Authz::PermissionGroups::Assignable.new(
        {
          name: "#{action}_#{resource_dir}",
          description: "Grants the ability to #{action} #{resource_dir}",
          permissions: ["#{action}_#{resource_dir}"],
          boundaries: %w[project]
        },
        Rails.root.join(
          ::Authz::PermissionGroups::Assignable::BASE_PATH, category_dir, resource_dir, "#{action}.yml"
        ).to_s
      )
    end

    def build_resource(name)
      ::Authz::PermissionGroups::Resource.new({ name: name, description: '' }, 'source_file')
    end

    let(:cd_application) { build_assignable('ci_cd', 'cd_application', 'read') }
    let(:catalog_resource) { build_assignable('ci_cd', 'catalog_resource', 'read') }
    let(:ci_cd_category) { ::Authz::PermissionGroups::Category.new({ name: 'CI/CD' }, 'source_file') }

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return(
        cd_application.name => cd_application,
        catalog_resource.name => catalog_resource
      )

      allow(::Authz::PermissionGroups::Resource).to receive(:get)
        .with('ci_cd/cd_application').and_return(build_resource('CD Application'))
      allow(::Authz::PermissionGroups::Resource).to receive(:get)
        .with('ci_cd/catalog_resource').and_return(build_resource('Catalog Resource'))
      allow(::Authz::PermissionGroups::Category).to receive(:get)
        .with('ci_cd').and_return(ci_cd_category)
    end

    it 'sorts resources case-insensitively by display name' do
      post_graphql(query, current_user: current_user)

      expect(permissions_data.pluck('resourceName')).to eq(['Catalog Resource', 'CD Application'])
    end
  end

  context 'when feature-flag `granular_personal_access_tokens` is disabled' do
    before do
      stub_feature_flags(granular_personal_access_tokens: false)
    end

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include("The resource that you are attempting to access does not exist")
    end
  end
end
