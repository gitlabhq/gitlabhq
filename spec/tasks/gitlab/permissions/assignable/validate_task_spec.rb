# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Assignable::ValidateTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run', :unlimited_max_formatted_output_length do
    let(:permission_name) { 'update_wiki' }
    let(:raw_permissions) { %w[update_wiki] }
    let(:permission_source_file) do
      'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml'
    end

    let(:permission_definition) do
      {
        name: permission_name,
        description: 'Update a wiki',
        permissions: raw_permissions,
        boundaries: ['project'],
        available_for: ['granular_access_token']
      }
    end

    let(:permission) do
      Authz::PermissionGroups::Assignable.new(permission_definition, Rails.root.join(permission_source_file).to_s)
    end

    subject(:run) { task.run }

    before do
      # Stub assignable permission definitions
      allow(Authz::PermissionGroups::Assignable).to receive_messages(get: nil,
        all: { permission.name.to_sym => permission })
      allow(Authz::PermissionGroups::Assignable).to receive(:get).with(permission_name.to_sym).and_return(permission)

      # Stub existence of raw permissions - used to validate permissions field
      # values matches defined raw permissions
      allow(Authz::Permission).to receive(:defined?).with(anything).and_return(false)
      allow(Authz::Permission).to receive(:defined?).with('update_wiki').and_return(true)

      # Stubs to make .metadata.yml file validation pass
      allow(Authz::PermissionGroups::Resource).to receive(:get).and_return(
        instance_double(Authz::PermissionGroups::Resource, definition: {})
      )
      allow(Authz::PermissionGroups::Category).to receive(:get).and_return(nil)
      allow(JSONSchemer).to receive(:schema).and_call_original
      allow(JSONSchemer).to receive(:schema)
        .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
        .and_return(instance_double(JSONSchemer::Schema, validate: []))

      # Skip the granular_access_token consumer check by default -- exercised separately below.
      allow(task).to receive(:validate_granular_access_token_consumers)
    end

    def stub_granular_token_consumers(rest_permissions: [], graphql_permissions: [])
      allow(task).to receive(:validate_granular_access_token_consumers).and_call_original

      authorization = rest_permissions.any? ? { permissions: rest_permissions } : nil
      route = instance_double(Grape::Router::Route, settings: { authorization: authorization })
      endpoint = instance_double(Grape::Endpoint, routes: [route], endpoints: nil)
      allow(::API::API).to receive(:endpoints).and_return([endpoint])

      directive = instance_double(::Directives::Authz::GranularScope,
        arguments: { permissions: graphql_permissions })
      allow(directive).to receive(:is_a?) { |klass| klass == ::Directives::Authz::GranularScope }
      type_struct = Struct.new(:directives, :fields)
      type_with_directives = type_struct.new([directive], {})
      schema_types = graphql_permissions.any? ? { 'StubType' => type_with_directives } : {}
      allow(GitlabSchema).to receive(:types).and_return(schema_types)
    end

    context 'when all permissions are valid' do
      it 'completes successfully' do
        expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
      end
    end

    context 'when permission is deprecated' do
      let(:permission_name) { 'manage_user_widget' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/user_widget/manage.yml'
      end

      let(:permission_definition) do
        {
          name: permission_name,
          description: 'Manage user widgets',
          permissions: %w[update_wiki],
          boundaries: ['user'],
          available_for: ['granular_access_token'],
          deprecated: true
        }
      end

      it 'skips boundary and action validations' do
        expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
      end
    end

    context 'when permission name has invalid format' do
      let(:permission_name) { 'InvalidName' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/InvalidName.yml'
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following assignable permissions have invalid names.
          #  Permission name must be in the format action_resource[_subresource].
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#naming-permissions
          #
          #    - InvalidName (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/InvalidName.yml)
          #
          #  The following permission names do not match their file path.
          #  The permission name must equal '<action>_<resource>' derived from the path.
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#naming-permissions
          #
          #    - InvalidName (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/InvalidName.yml)
          #      Path must match 'config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml' based on <resource> and <action> values from 'InvalidName' ('<action>_<resource>')
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when action is disallowed' do
      let(:permission_name) { 'manage_wiki' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/manage.yml'
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following assignable permissions contain a disallowed action.
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#disallowed-actions
          #
          #    - manage_wiki: Prefer a granular action over manage. (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/manage.yml)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when resource name starts with a boundary prefix' do
      let(:permission_name) { 'read_user_ssh_key' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/system_access/user_ssh_key/read.yml'
      end

      let(:permission_definition) do
        {
          name: permission_name,
          description: 'Grants the ability to read user SSH keys',
          permissions: %w[read_user_ssh_key],
          boundaries: ['user'],
          available_for: ['granular_access_token']
        }
      end

      before do
        allow(Authz::Permission).to receive(:defined?).with('read_user_ssh_key').and_return(true)
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following assignable permissions encode a resource boundary in their name.
          #  The permission name should not include the boundary (project, group, user) as a prefix.
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#avoiding-resource-boundaries-in-permission-names
          #
          #    - read_user_ssh_key: Resource should not start with boundary 'user'. (config/authz/permission_groups/assignable_permissions/system_access/user_ssh_key/read.yml)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when schema is invalid' do
      context 'with missing and invalid keys' do
        let(:permission_definition) do
          {
            name: permission_name,
            key: 'not allowed'
          }
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permissions failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
            #
            #    - update_wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml)
            #        - property '/key' is invalid: error_type=schema
            #        - root is missing required keys: description, permissions, boundaries, available_for
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'with invalid permissions' do
        let(:permission_definition) { super().merge(permissions: %w[unknown]) }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permissions failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
            #
            #    - update_wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml)
            #        - property '/permissions/0' does not match format: known_permissions
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'with invalid boundaries' do
        let(:permission_definition) { super().merge(boundaries: %w[unknown]) }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permissions failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
            #
            #    - update_wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml)
            #        - property '/boundaries/0' is not one of: ["instance", "group", "project", "user"]
            #
            #######################################################################
          OUTPUT
        end
      end
    end

    context 'when there are duplicate permission names' do
      before do
        # This assumes that there are more at least two YML files in
        # config/authz/permission_groups/assignable_permissions/
        allow(YAML).to receive(:safe_load).and_return({ 'name' => 'duplicated_permission_name' })
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions have duplicate names.
          #  Assignable permissions must have unique names.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#important-constraints
          #
          #    - duplicated_permission_name
          #
          #######################################################################
        OUTPUT
      end

      context 'when the duplicate name matches a known permission' do
        before do
          allow(YAML).to receive(:safe_load).and_return({ 'name' => permission_name })
        end

        it 'includes the source path in the error' do
          expect { run }.to raise_error(SystemExit).and output(
            %r{- update_wiki \(config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update\.yml\)}
          ).to_stdout
        end
      end
    end

    context 'when raw permissions are used in multiple assignable permissions' do
      let(:zebra_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/zebra/update.yml'
      end

      let(:apple_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/apple/update.yml'
      end

      let(:zebra_assignable) do
        Authz::PermissionGroups::Assignable.new(
          {
            name: 'update_zebra',
            description: 'Zebra assignable',
            permissions: %w[beta_permission alpha_permission unique_one],
            boundaries: ['project'],
            available_for: ['granular_access_token']
          },
          Rails.root.join(zebra_source_file).to_s
        )
      end

      let(:apple_assignable) do
        Authz::PermissionGroups::Assignable.new(
          {
            name: 'update_apple',
            description: 'Apple assignable',
            permissions: %w[beta_permission alpha_permission unique_two],
            boundaries: ['project'],
            available_for: ['granular_access_token']
          },
          Rails.root.join(apple_source_file).to_s
        )
      end

      before do
        allow(Authz::PermissionGroups::Assignable).to receive(:all).and_return(
          { update_zebra: zebra_assignable, update_apple: apple_assignable }
        )
        allow(Authz::Permission).to receive(:defined?).with(anything).and_return(true)
      end

      it 'returns an error with sorted raw permissions and sorted assignable names' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following raw permissions are used in multiple assignable permissions.
          #  Each raw permission should only belong to one assignable permission.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#important-constraints
          #
          #    - alpha_permission: found in update_apple (config/authz/permission_groups/assignable_permissions/wiki_category/apple/update.yml), update_zebra (config/authz/permission_groups/assignable_permissions/wiki_category/zebra/update.yml)
          #    - beta_permission: found in update_apple (config/authz/permission_groups/assignable_permissions/wiki_category/apple/update.yml), update_zebra (config/authz/permission_groups/assignable_permissions/wiki_category/zebra/update.yml)
          #
          #######################################################################
        OUTPUT
      end

      context 'when one of the duplicates is deprecated' do
        let(:apple_assignable) do
          Authz::PermissionGroups::Assignable.new(
            {
              name: 'update_apple',
              description: 'Apple assignable',
              permissions: %w[beta_permission alpha_permission unique_two],
              boundaries: ['project'],
              available_for: ['granular_access_token'],
              deprecated: true
            },
            Rails.root.join(apple_source_file).to_s
          )
        end

        it 'does not flag the shared raw permissions as duplicates' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end
    end

    context 'when file path does not match /<category>/<resource>/<action>.yml' do
      let(:permission_name) { 'update_weekee' }
      let(:raw_permissions) { %w[update_wiki] }
      let(:permission_source_file) { 'config/authz/permission_groups/assignable_permissions/weekee/update.yml' }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permission definitions do not exist at the expected path.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#understanding-the-directory-structure
          #
          #    - update_weekee in config/authz/permission_groups/assignable_permissions/weekee/update.yml
          #      Expected path: config/authz/permission_groups/assignable_permissions/<category>/weekee/update.yml
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when permission name does not match path-derived name' do
      let(:permission_name) { 'update_old_wiki' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml'
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permission names do not match their file path.
          #  The permission name must equal '<action>_<resource>' derived from the path.
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#naming-permissions
          #
          #    - update_old_wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml)
          #      Path must match 'config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml' based on <resource> and <action> values from 'update_old_wiki' ('<action>_<resource>')
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when permission name matches path-derived name' do
      let(:permission_name) { 'update_wiki' }
      let(:permission_source_file) do
        'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml'
      end

      it 'completes successfully' do
        expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
      end
    end

    describe 'permission resource validation' do
      let(:category) { 'wiki_category' }
      let(:resource) { 'wiki' }
      let(:permission_source_file) do
        "config/authz/permission_groups/assignable_permissions/#{category}/#{resource}/update.yml"
      end

      context 'when resource metadata for the permission is not in the correct schema' do
        let(:resource_definition) do
          definition = { invalid_key: 'not allowed' }
          Authz::PermissionGroups::Resource.new(definition, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with("#{category}/#{resource}")
            .and_return(resource_definition)
          allow(JSONSchemer).to receive(:schema)
            .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
            .and_call_original
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following assignable permission resource metadata file failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#when-do-you-need-metadata-files
            #
            #    - wiki_category/wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/.metadata.yml)
            #        - property '/invalid_key' is invalid: error_type=schema
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when resource description does not include <actions> interpolation' do
        let(:resource_definition) do
          definition = { description: 'A description without actions interpolation.' }
          Authz::PermissionGroups::Resource.new(definition, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with("#{category}/#{resource}")
            .and_return(resource_definition)
          allow(JSONSchemer).to receive(:schema)
            .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
            .and_call_original
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following assignable permission resource metadata file failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#when-do-you-need-metadata-files
            #
            #    - wiki_category/wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/.metadata.yml)
            #        - property '/description' does not match pattern: <actions>
            #
            #######################################################################
          OUTPUT
        end
      end
    end

    describe 'permission category validation' do
      let(:category) { 'wiki_category' }
      let(:resource) { 'wiki' }
      let(:permission_source_file) do
        "config/authz/permission_groups/assignable_permissions/#{category}/#{resource}/update.yml"
      end

      context 'when category metadata exists and is not in the correct schema' do
        let(:category_definition) do
          definition = { invalid_key: 'not allowed' }
          Authz::PermissionGroups::Category.new(definition, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with(category)
            .and_return(category_definition)
          allow(JSONSchemer).to receive(:schema)
            .with(Rails.root.join("#{described_class::PERMISSION_DIR}/category_metadata_schema.json"))
            .and_call_original
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following assignable permission category metadata file failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#understanding-the-directory-structure
            #
            #    - wiki_category (config/authz/permission_groups/assignable_permissions/wiki_category/.metadata.yml)
            #        - property '/invalid_key' is invalid: error_type=schema
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when category metadata exists and is valid' do
        let(:category_definition) do
          definition = { name: 'Wiki' }
          Authz::PermissionGroups::Category.new(definition, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with(category)
            .and_return(category_definition)
          allow(JSONSchemer).to receive(:schema)
            .with(Rails.root.join("#{described_class::PERMISSION_DIR}/category_metadata_schema.json"))
            .and_call_original
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end
    end

    describe 'empty resource directory validation' do
      context 'when a resource directory contains only .metadata.yml' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/*/*/')
            .and_return(['config/authz/permission_groups/assignable_permissions/some_category/empty_resource/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/some_category/empty_resource/*.yml')
            .and_return([
              'config/authz/permission_groups/assignable_permissions/some_category/empty_resource/.metadata.yml'
            ])
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following resource directories contain only a .metadata.yml file with no permission definitions.
            #  Either add permission definitions or remove the directory.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#understanding-the-directory-structure
            #
            #    - config/authz/permission_groups/assignable_permissions/some_category/empty_resource/
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when a resource directory contains .metadata.yml and permission files' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/*/*/')
            .and_return(['config/authz/permission_groups/assignable_permissions/some_category/valid_resource/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/some_category/valid_resource/*.yml')
            .and_return([
              'config/authz/permission_groups/assignable_permissions/some_category/valid_resource/.metadata.yml',
              'config/authz/permission_groups/assignable_permissions/some_category/valid_resource/read.yml'
            ])
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end
    end

    describe 'empty category directory validation' do
      context 'when a category directory contains only .metadata.yml with no resource subdirectories' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/*/')
            .and_return(['config/authz/permission_groups/assignable_permissions/empty_category/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/empty_category/*/')
            .and_return([])
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('config/authz/permission_groups/assignable_permissions/empty_category/.metadata.yml')
            .and_return(true)
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following category directories contain only a .metadata.yml file with no resource subdirectories.
            #  Either add resource subdirectories or remove the directory.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#understanding-the-directory-structure
            #
            #    - config/authz/permission_groups/assignable_permissions/empty_category/
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when a category directory contains .metadata.yml and resource subdirectories' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/*/')
            .and_return(['config/authz/permission_groups/assignable_permissions/valid_category/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permission_groups/assignable_permissions/valid_category/*/')
            .and_return(['config/authz/permission_groups/assignable_permissions/valid_category/some_resource/'])
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('config/authz/permission_groups/assignable_permissions/valid_category/.metadata.yml')
            .and_return(true)
          allow(File).to receive(:directory?).and_call_original
          allow(File).to receive(:directory?)
            .with('config/authz/permission_groups/assignable_permissions/valid_category/some_resource/')
            .and_return(true)
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end
    end

    describe 'granular access token consumer validation' do
      context 'when the assignable is available_for granular_access_token and a REST route references it' do
        before do
          stub_granular_token_consumers(rest_permissions: %w[update_wiki])
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end

      context 'when the assignable is available_for granular_access_token and a GraphQL directive references it' do
        before do
          stub_granular_token_consumers(graphql_permissions: %w[update_wiki])
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end

      context 'when the assignable is available_for granular_access_token but no consumer references it' do
        before do
          stub_granular_token_consumers
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following assignable permissions declare `available_for: granular_access_token` but none of their raw permissions are referenced by any REST authorization or GraphQL granular scope directive.
            #  Either remove `granular_access_token` from `available_for`, or reference one of the raw permissions in a route/directive.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#available-for-consumers
            #
            #    - update_wiki (config/authz/permission_groups/assignable_permissions/wiki_category/wiki/update.yml)
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when the assignable is not available_for granular_access_token' do
        let(:permission_definition) { super().merge(available_for: ['role']) }

        before do
          stub_granular_token_consumers
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end

      context 'when the only referencing route uses skip_granular_token_authorization' do
        before do
          allow(task).to receive(:validate_granular_access_token_consumers).and_call_original
          authorization = { permissions: %w[update_wiki], skip_granular_token_authorization: :job_token_auth }
          route = instance_double(Grape::Router::Route, settings: { authorization: authorization })
          endpoint = instance_double(Grape::Endpoint, routes: [route], endpoints: nil)
          allow(::API::API).to receive(:endpoints).and_return([endpoint])
          allow(GitlabSchema).to receive(:types).and_return({})
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(
            /The following assignable permissions declare `available_for: granular_access_token`/
          ).to_stdout
        end
      end

      context 'when the assignable is deprecated' do
        let(:permission_definition) { super().merge(deprecated: true) }

        before do
          stub_granular_token_consumers
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end

      context 'when the raw permission is in GRANULAR_TOKEN_NON_API_CONSUMERS' do
        let(:raw_permissions) { %w[download_code] }

        before do
          allow(Authz::Permission).to receive(:defined?).with('download_code').and_return(true)
          stub_granular_token_consumers
        end

        it 'completes successfully' do
          expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
        end
      end
    end
  end
end
