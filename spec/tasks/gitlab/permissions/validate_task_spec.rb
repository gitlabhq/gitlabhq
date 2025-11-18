# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::ValidateTask, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run', :unlimited_max_formatted_output_length do
    let(:exclusion_list) { ['undefined_permission'] }
    let(:exclusion_list_data) { exclusion_list.join("\n") }
    let(:exclusion_file) { Tempfile.new("definitions_todo.txt") }
    let(:permission_name) { 'defined_permission' }
    let(:permission_source_file) { 'config/authz/permissions/permission/defined.yml' }
    let(:permission_definition) do
      {
        name: permission_name,
        description: 'a defined permission',
        feature_category: 'permissions'
      }
    end

    let(:permission) { Authz::Permission.new(permission_definition, permission_source_file) }

    let(:enabled_permissions) { [] }
    let(:mock_policy_class) do
      name = permission_name
      other_enabled = enabled_permissions

      Class.new(DeclarativePolicy::Base) do
        rule { default }.enable name.to_sym

        other_enabled.each do |permission|
          rule { default }.enable permission
        end
      end
    end

    subject(:run) { task.run }

    before do
      allow(DeclarativePolicy::Base).to receive(:descendants).and_return([mock_policy_class])

      # Stub permission definitions
      allow(Authz::Permission).to receive_messages(get: nil, all: { permission.name.to_sym => permission })
      allow(Authz::Permission).to receive(:get).with(permission_name.to_sym).and_return(permission)

      # Stub exclusion list
      File.open(exclusion_file.path, "w+b") { |f| f.write exclusion_list_data }
      stub_const('Tasks::Gitlab::Permissions::ValidateTask::PERMISSION_TODO_FILE', exclusion_file.path)
    end

    context 'when all permissions are valid' do
      it 'completes successfully' do
        expect { run }.to output(/Permission definitions are up-to-date/).to_stdout
      end
    end

    context 'when a permission is missing a definition file' do
      let(:enabled_permissions) { %i[undefined_permission] }

      # We will return an empty array when the file does not exist, which is what we need here.
      # Behaving like the file doesn't exists allows us to test that behavior without another spec.
      before do
        stub_const('Tasks::Gitlab::Permissions::ValidateTask::PERMISSION_TODO_FILE', 'nonexistent')
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions are missing a definition file.
          #  Run bundle exec rails generate authz:permission <NAME> to generate definition files.
          #
          #    - undefined_permission
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission is in the exclusion list' do
      let(:exclusion_list) { %w[undefined_permission defined_permission] }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions have a definition file.
          #  Remove them from config/authz/permissions/definitions_todo.txt.
          #
          #    - defined_permission
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission is in the exclusion list and a permission is not defined' do
      let(:exclusion_list) { ['defined_permission'] }
      let(:enabled_permissions) { %i[undefined_permission] }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions are missing a definition file.
          #  Run bundle exec rails generate authz:permission <NAME> to generate definition files.
          #
          #    - undefined_permission
          #
          #  The following permissions have a definition file.
          #  Remove them from config/authz/permissions/definitions_todo.txt.
          #
          #    - defined_permission
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission is not in the correct schema' do
      let(:permission_definition) do
        {
          name: permission_name,
          description: 'a defined permission',
          feature_category: 'unknown',
          action: 'defined',
          resource: 'permission',
          key: 'not allowed'
        }
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions failed schema validation.
          #
          #    - defined_permission
          #        - property '/feature_category' does not match format: known_product_category
          #        - property '/key' is invalid: error_type=schema
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission contains a disallowed action' do
      let(:permission_name) { 'admin_permission' }
      let(:permission_source_file) { 'config/authz/permissions/permission/admin.yml' }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions contain a disallowed action.
          #
          #    - admin_permission: Prefer a granular action over admin.
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when the permission definition is at the wrong file location' do
      let(:permission_source_file) { 'config/authz/permissions/defined_permission.yml' }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permission definitions do not exist at the expected path.
          #
          #    - Name: defined_permission
          #      Expected Path: config/authz/permissions/permission/defined.yml
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when the permission name is not in the correct format' do
      let(:permission_name) { 'defined_permission-123' }
      let(:permission_source_file) { 'config/authz/permissions/permission-123/defined.yml' }

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions have invalid names.
          #  Permission name must be in the format action_resource[_subresource].
          #
          #    - defined_permission-123
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when the permission has a definition file but is not defined in declarative policy' do
      before do
        allow(DeclarativePolicy::Base).to receive(:descendants).and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions have a definition file but are not found in declarative policy.
          #  Remove the definition files for the unkonwn permissions.
          #
          #    - defined_permission
          #
          #######################################################################
        OUTPUT
      end
    end
  end

  describe '#validate_name' do
    using RSpec::Parameterized::TableSyntax

    let(:permission) { Authz::Permission.new({ name: name }, '') }

    subject(:validate_name) { task.send(:validate_name, permission) }

    where(:name, :valid) do
      "valid_permission"     | true
      "valid_permission_two" | true
      "_invalid_permission"  | false
      "Invalid_permission"   | false
      "invalid-permission"   | false
      "invalid_permission_"  | false
    end

    with_them do
      it 'returns the expected result', :aggregate_failures do
        validate_name

        if valid
          expect(task.instance_variable_get(:@violations)[:name]).not_to include(name)
        else
          expect(task.instance_variable_get(:@violations)[:name]).to include(name)
        end
      end
    end
  end
end
