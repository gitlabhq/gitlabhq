# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::ValidateTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run', :unlimited_max_formatted_output_length do
    let(:exclusion_list) { ['undefined_permission'] }
    let(:exclusion_list_data) { exclusion_list.join("\n") }
    let(:exclusion_todo_path) { 'tmp/tests/definitions_todo.txt' }
    let(:permission_name) { 'defined_permission' }
    let(:permission_source_file) { 'config/authz/permissions/permission/defined.yml' }
    let(:permission_definition) do
      {
        name: permission_name,
        description: 'a defined permission'
      }
    end

    let(:permission) { Authz::Permission.new(permission_definition, Rails.root.join(permission_source_file).to_s) }

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
      FileUtils.mkdir_p(Rails.root.join('tmp/tests'))
      File.write(Rails.root.join(exclusion_todo_path), exclusion_list_data)
      stub_const('Tasks::Gitlab::Permissions::ValidateTask::PERMISSION_TODO_FILE', exclusion_todo_path)

      # Stubs to make .metadata.yml file validation pass
      allow(Authz::Resource).to receive(:get).and_return(instance_double(Authz::Resource, definition: {}))
      allow(JSONSchemer).to receive(:schema).and_call_original
      allow(JSONSchemer).to receive(:schema)
        .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
        .and_return(instance_double(JSONSchemer::Schema, validate: []))
    end

    after do
      FileUtils.rm_f(Rails.root.join(exclusion_todo_path))
    end

    context 'when all permissions are valid' do
      it 'completes successfully' do
        expect { run }.to output(/Permission definitions are up-to-date/).to_stdout
      end
    end

    context 'when a missing permission is in the exclusion list' do
      let(:exclusion_list) { %w[missing_but_excluded] }
      let(:exclusion_list_data) { "\n#{exclusion_list.join("\n")}\n" }
      let(:enabled_permissions) { %i[missing_but_excluded] }

      it 'does not report a violation' do
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
          #  Run bin/permission <NAME> to generate definition files.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - undefined_permission
          #
          #######################################################################
        OUTPUT
      end

      context 'when the policy source can be resolved' do
        before do
          allow(task).to receive(:policy_source_path).and_return('app/policies/project_policy.rb:42')
        end

        it 'includes the policy source file in the error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permissions are missing a definition file.
            #  Run bin/permission <NAME> to generate definition files.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
            #
            #    - undefined_permission (app/policies/project_policy.rb:42)
            #
            #######################################################################
          OUTPUT
        end
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
          #    - defined_permission (config/authz/permissions/permission/defined.yml, tmp/tests/definitions_todo.txt:2)
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
          #  Run bin/permission <NAME> to generate definition files.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - undefined_permission
          #
          #  The following permissions have a definition file.
          #  Remove them from config/authz/permissions/definitions_todo.txt.
          #
          #    - defined_permission (config/authz/permissions/permission/defined.yml, tmp/tests/definitions_todo.txt:1)
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
          key: 'not allowed'
        }
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions failed schema validation.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-fields
          #
          #    - defined_permission (config/authz/permissions/permission/defined.yml)
          #        - property '/key' is invalid: error_type=schema
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission contains a disallowed action' do
      described_class::DISALLOWED_ACTIONS.each do |disallowed_action, preferred|
        context "when action is #{disallowed_action}" do
          let(:permission_name) { "#{disallowed_action}_permission" }
          let(:permission_source_file) { "config/authz/permissions/permission/#{disallowed_action}.yml" }

          it 'returns an error' do
            expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions contain a disallowed action.
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#disallowed-actions
          #
          #    - #{permission_name}: Prefer #{preferred} over #{disallowed_action}. (#{permission_source_file})
          #
          #######################################################################
            OUTPUT
          end
        end
      end
    end

    describe 'file path checks' do
      context 'when the permission definition is not under a resource directory' do
        let(:permission_source_file) { 'config/authz/permissions/defined_permission.yml' }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permission definitions do not exist at the expected path.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-naming-and-validation
            #
            #    - defined_permission in config/authz/permissions/defined_permission.yml
            #      Expected path: config/authz/permissions/<resource>/defined_permission.yml
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when the resource directory is not directly under config/authz/permissions/' do
        let(:permission_source_file) { 'config/authz/permissions/another_dir/resource_dir/defined_permission.yml' }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permission definitions do not exist at the expected path.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-naming-and-validation
            #
            #    - defined_permission in config/authz/permissions/another_dir/resource_dir/defined_permission.yml
            #      Expected path: config/authz/permissions/resource_dir/defined_permission.yml
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when the permission definition path does not match the permission name' do
        let(:permission_name) { 'action_on_a_resource' } # action: 'action_on', resource: 'a_resource'
        let(:permission_source_file) { 'config/authz/permissions/wrong_resource_name/wrong_action_name.yml' }

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permission definitions do not exist at the expected path.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-naming-and-validation
            #
            #    - action_on_a_resource in config/authz/permissions/wrong_resource_name/wrong_action_name.yml
            #      Path must match 'config/authz/permissions/<resource>/<action>.yml' based on <resource> and <action> values from 'action_on_a_resource' ('<action>_<resource>')
            #
            #######################################################################
          OUTPUT
        end
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
          #  Learn more: https://docs.gitlab.com/development/permissions/conventions/#naming-permissions
          #
          #    - defined_permission-123 (config/authz/permissions/permission-123/defined.yml)
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
          #  Remove the definition files for the unknown permissions.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - defined_permission (config/authz/permissions/permission/defined.yml)
          #
          #######################################################################
        OUTPUT
      end
    end

    describe 'permission resource validation' do
      let(:resource) { 'permission' }
      let(:permission_source_file) { "config/authz/permissions/#{resource}/defined.yml" }

      context 'when resource definition for the permission does not exist' do
        before do
          allow(Authz::Resource).to receive(:get).with(resource).and_return(nil)
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following permission resource directories are missing a .metadata.yml file.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#resource-metadata-fields
            #
            #    - config/authz/permissions/**/permission/
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when resource definition for the permission is not in the correct schema' do
        let(:resource_definition) do
          definition = { description: 'The resource', feature_category: 'unknown_feature_category' }
          Authz::Resource.new(definition, 'source_file')
        end

        before do
          allow(Authz::Resource).to receive(:get).with(resource).and_return(resource_definition)
          allow(JSONSchemer).to receive(:schema)
            .with(Rails.root.join("#{described_class::PERMISSION_DIR}/resource_metadata_schema.json"))
            .and_call_original
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following resource metadata files failed schema validation.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#resource-metadata-fields
            #
            #    - permission
            #        - property '/feature_category' does not match format: known_product_category
            #
            #######################################################################
          OUTPUT
        end
      end
    end

    describe 'empty resource directory validation' do
      context 'when a resource directory contains only .metadata.yml' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permissions/*/')
            .and_return(['config/authz/permissions/empty_resource/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permissions/empty_resource/*.yml')
            .and_return(['config/authz/permissions/empty_resource/.metadata.yml'])
        end

        it 'returns an error' do
          expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
            #######################################################################
            #
            #  The following resource directories contain only a .metadata.yml file with no permission definitions.
            #  Either add permission definitions or remove the directory.
            #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-naming-and-validation
            #
            #    - config/authz/permissions/empty_resource/
            #
            #######################################################################
          OUTPUT
        end
      end

      context 'when a resource directory contains .metadata.yml and permission files' do
        before do
          allow(Dir).to receive(:glob).and_call_original
          allow(Dir).to receive(:glob)
            .with('config/authz/permissions/*/')
            .and_return(['config/authz/permissions/valid_resource/'])
          allow(Dir).to receive(:glob)
            .with('config/authz/permissions/valid_resource/*.yml')
            .and_return([
              'config/authz/permissions/valid_resource/.metadata.yml',
              'config/authz/permissions/valid_resource/read.yml'
            ])
        end

        it 'completes successfully' do
          expect { run }.to output(/Permission definitions are up-to-date/).to_stdout
        end
      end
    end
  end

  describe '#validate_name' do
    using RSpec::Parameterized::TableSyntax

    let(:permission) { Authz::Permission.new({ name: name }, '') }

    subject(:validate_name) { task.send(:validate_name, permission) }

    where(:name, :valid) do
      "valid_permission"           | true
      "valid_permission_two"       | true
      "_valid_private_permission"  | true
      "Invalid_permission"         | false
      "invalid-permission"         | false
      "invalid_permission_"        | false
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

  describe '#permission_source_path' do
    it 'returns nil when the permission is not found' do
      allow(Authz::Permission).to receive(:get).with(:unknown).and_return(nil)

      expect(task.send(:permission_source_path, :unknown)).to be_nil
    end
  end

  describe '#policy_source_path' do
    context 'when the policy class has no source location' do
      it 'returns nil' do
        klass = Class.new(DeclarativePolicy::Base)
        allow(klass).to receive(:name).and_return('NonexistentPolicy')
        allow(Object).to receive(:const_source_location).with('NonexistentPolicy').and_return(nil)

        expect(task.send(:policy_source_path, klass)).to be_nil
      end
    end

    context 'when called without a permission name' do
      it 'returns the file path without a line number' do
        klass = Class.new(DeclarativePolicy::Base)
        allow(klass).to receive(:name).and_return('TestPolicy')
        allow(Object).to receive(:const_source_location)
          .with('TestPolicy').and_return([Rails.root.join('app/policies/test_policy.rb').to_s, 1])

        expect(task.send(:policy_source_path, klass)).to eq('app/policies/test_policy.rb')
      end
    end

    context 'when the permission is found in the file' do
      it 'returns the file path with a line number' do
        file_path = Rails.root.join('app/policies/test_policy.rb').to_s
        klass = Class.new(DeclarativePolicy::Base)
        allow(klass).to receive(:name).and_return('TestPolicy')
        allow(Object).to receive(:const_source_location)
          .with('TestPolicy').and_return([file_path, 1])
        allow(File).to receive(:foreach).with(file_path).and_return(
          ["  rule { default }.policy do\n", "    enable :read_project\n"].each
        )

        expect(task.send(:policy_source_path, klass, :read_project)).to eq('app/policies/test_policy.rb:2')
      end
    end

    context 'when the permission is not found in the file' do
      it 'returns the file path without a line number' do
        file_path = Rails.root.join('app/policies/test_policy.rb').to_s
        klass = Class.new(DeclarativePolicy::Base)
        allow(klass).to receive(:name).and_return('TestPolicy')
        allow(Object).to receive(:const_source_location)
          .with('TestPolicy').and_return([file_path, 1])
        allow(File).to receive(:foreach).with(file_path).and_return(
          ["  enable :other_permission\n"].each
        )

        expect(task.send(:policy_source_path, klass, :nonexistent_perm)).to eq('app/policies/test_policy.rb')
      end
    end
  end

  describe '#add_definition_violation' do
    it 'handles permissions not found in any policy' do
      task.instance_variable_set(:@permission_policies, {})

      task.send(:add_definition_violation, :orphan_permission)

      violation = task.instance_variable_get(:@violations)[:definition].last
      expect(violation).to eq({ name: :orphan_permission, sources: [] })
    end
  end
end
