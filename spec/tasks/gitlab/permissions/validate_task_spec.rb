# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::ValidateTask, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run' do
    let(:exclusion_list) { ['undefined_permission'] }
    let(:exclusion_list_data) { exclusion_list.join("\n") }
    let(:exclusion_file) { Tempfile.new("definitions_todo.txt") }
    let(:permission) do
      Authz::Permission.new({
        name: 'defined_permission',
        description: 'a defined permission',
        feature_category: 'permissions',
        scopes: %w[project group]
      })
    end

    let(:mock_policy_class) do
      Class.new(DeclarativePolicy::Base) do
        rule { default }.enable :defined_permission
        rule { default }.enable :undefined_permission
      end
    end

    subject(:run) { task.run }

    before do
      allow(DeclarativePolicy::Base).to receive(:descendants).and_return([mock_policy_class])

      # Stub permission definitions
      allow(Authz::Permission).to receive(:get).and_return(nil)
      allow(Authz::Permission).to receive(:get).with(:defined_permission).and_return(permission)

      # Stub exclusion list
      File.open(exclusion_file.path, "w+b") { |f| f.write exclusion_list_data }
      stub_const('Tasks::Gitlab::Permissions::ValidateTask::PERMISSION_TODO_FILE', exclusion_file.path)
    end

    context 'when all permissions are valid' do
      it 'completes successfully' do
        expect { run }.to output(/Permissions documentation is up-to-date/).to_stdout
      end
    end

    context 'when a permission is missing a definition file' do
      # We will return an empty array when the file does not exist, which is what we need here.
      # Behaving like the file doesn't exists allows us to test that behavior without another spec.
      before do
        stub_const('Tasks::Gitlab::Permissions::ValidateTask::PERMISSION_TODO_FILE', 'nonexistent')
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions are missing a documentation file.
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
          #  The following permissions have a documentation file.
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

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions are missing a documentation file.
          #
          #    - undefined_permission
          #
          #  The following permissions have a documentation file.
          #  Remove them from config/authz/permissions/definitions_todo.txt.
          #
          #    - defined_permission
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission is not in the correct schema' do
      let(:permission) do
        Authz::Permission.new({
          name: 'defined_permission',
          description: 'a defined permission',
          feature_category: 'unknown',
          scopes: %w[project foobar],
          key: 'not allowed'
        })
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions failed schema validation.
          #
          #    - defined_permission
          #        - property '/feature_category' does not match format: known_product_category
          #        - property '/scopes/1' is not one of: ["admin", "instance", "group", "project"]
          #        - property '/key' is invalid: error_type=schema
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a defined permission contains a disallowed action' do
      let(:permission) do
        Authz::Permission.new({
          name: 'admin_permission',
          description: 'a defined permission',
          feature_category: 'permissions',
          scopes: %w[project]
        })
      end

      let(:mock_policy_class) do
        Class.new(DeclarativePolicy::Base) do
          rule { default }.enable :admin_permission
        end
      end

      before do
        allow(Authz::Permission).to receive(:get).with(:admin_permission).and_return(permission)
      end

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
  end
end
