# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::ValidateTask, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#run' do
    let(:exclusion_list) { ['undefined_permission'] }
    let(:exclusion_list_data) { exclusion_list.join("\n") }
    let(:exclusion_file) { Tempfile.new("definitions_todo.txt") }
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
      allow(Authz::Permission).to receive(:get).with(:defined_permission).and_return(true)

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
          #  The following permissions are missing a documentation file
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
          #  The following permissions have an entry in config/authz/permissions/definitions_todo.txt but are defined.
          #  Remove any defined permissions from config/authz/permissions/definitions_todo.txt.
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
          #  The following permissions are missing a documentation file
          #
          #    - undefined_permission
          #
          #  The following permissions have an entry in config/authz/permissions/definitions_todo.txt but are defined.
          #  Remove any defined permissions from config/authz/permissions/definitions_todo.txt.
          #
          #    - defined_permission
          #
          #######################################################################
        OUTPUT
      end
    end
  end
end
