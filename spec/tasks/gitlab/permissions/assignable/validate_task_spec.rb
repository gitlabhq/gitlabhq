# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Assignable::ValidateTask, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run', :unlimited_max_formatted_output_length do
    let(:permission_name) { 'modify_wiki' }
    let(:raw_permissions) { %w[update_wiki] }
    let(:permission_source_file) do
      'config/authz/permission_groups/assignable_permissions/wiki_category/wiki/modify.yml'
    end

    let(:permission_definition) do
      {
        name: permission_name,
        description: 'Modify a wiki',
        permissions: raw_permissions,
        boundaries: ['project']
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

      # Stubs to make _metadata.yml file validation pass
      allow(Authz::PermissionGroups::Resource).to receive(:get).and_return(
        instance_double(Authz::PermissionGroups::Resource, definition: {})
      )
      allow(Authz::PermissionGroups::Category).to receive(:get).and_return(nil)
      allow(JSONSchemer).to receive(:schema).and_call_original
      allow(JSONSchemer).to receive(:schema)
        .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
        .and_return(instance_double(JSONSchemer::Schema, validate: []))
    end

    context 'when all permissions are valid' do
      it 'completes successfully' do
        expect { run }.to output(/Assignable permission definitions are up-to-date/).to_stdout
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
            #
            #    - modify_wiki
            #        - property '/key' is invalid: error_type=schema
            #        - root is missing required keys: description, permissions, boundaries
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
            #
            #    - modify_wiki
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
            #
            #    - modify_wiki
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
          #
          #    - duplicated_permission_name
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when file path does not match /<category>/<resource>/<action>.yml' do
      let(:permission_source_file) { 'config/authz/permission_groups/assignable_permissions/weekee/update.yml' }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permission definitions do not exist at the expected path.
          #
          #    - modify_wiki in config/authz/permission_groups/assignable_permissions/weekee/update.yml
          #      Expected path: config/authz/permission_groups/assignable_permissions/<category>/weekee/update.yml
          #
          #######################################################################
        OUTPUT
      end
    end

    describe 'permission resource validation' do
      let(:category) { 'wiki_category' }
      let(:resource) { 'wiki' }
      let(:permission_source_file) do
        "config/authz/permission_groups/assignable_permissions/#{category}/#{resource}/modify.yml"
      end

      context 'when resource metadata for the permission does not exist' do
        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with("#{category}/#{resource}")
            .and_return(nil)
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following assignable permission resource directories are missing a _metadata.yml file.
            #
            #    - config/authz/permission_groups/assignable_permissions/wiki_category/wiki/
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when resource metadata for the permission is not in the correct schema' do
        let(:resource_definition) do
          definition = { name: 'Wiki Resource' } # Missing required 'description' field
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
            #
            #    - wiki_category/wiki
            #        - root is missing required keys: description
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
        "config/authz/permission_groups/assignable_permissions/#{category}/#{resource}/modify.yml"
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
            #
            #    - wiki_category
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
  end
end
