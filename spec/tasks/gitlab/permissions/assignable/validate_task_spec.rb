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
        feature_category: 'permissions',
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
            #        - root is missing required keys: description, feature_category, permissions, boundaries
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'with invalid feature_category' do
        let(:permission_definition) { super().merge(feature_category: 'unknown') }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permissions failed schema validation.
            #
            #    - modify_wiki
            #        - property '/feature_category' does not match format: known_product_category
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
  end
end
