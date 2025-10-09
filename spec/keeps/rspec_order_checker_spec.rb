# frozen_string_literal: true

require 'tmpdir'
require 'spec_helper'
require './keeps/rspec_order_checker'

RSpec.describe Keeps::RspecOrderChecker, feature_category: :tooling do
  let(:spec_files_limit) { 2 }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:todo_yaml_path) { File.join(tmp_dir, 'rspec_order_todo.yml') }
  let(:failure_yaml_path) { File.join(tmp_dir, 'rspec_order_failures.yml') }
  let(:check_script) { 'scripts/rspec_check_order_dependence' }

  subject(:keep) { described_class.new(limit_specs: spec_files_limit) }

  before do
    stub_const("#{described_class}::TODO_YAML_PATH", todo_yaml_path)
    stub_const("#{described_class}::FAILURE_YAML_PATH", failure_yaml_path)
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  describe '#each_identified_change' do
    context 'when TODO file does not exist' do
      it 'does not yield any changes' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when TODO file contains specs' do
      let(:todo_specs) do
        [
          './spec/models/user_spec.rb',
          './spec/models/project_spec.rb',
          './spec/controllers/application_controller_spec.rb',
          './ee/spec/models/license_spec.rb' # filter out EE specs for now
        ]
      end

      before do
        File.write(todo_yaml_path, todo_specs.to_yaml)
        FileUtils.touch(failure_yaml_path)
        # create failure file for tracking
      end

      it 'yields a change, filters out EE specs and limits to specified count' do
        expect { |b| keep.each_identified_change(&b) }.to yield_with_args(
          have_attributes(
            context: hash_including(
              entries_to_check: [
                'spec/controllers/application_controller_spec.rb',
                'spec/models/project_spec.rb'
              ],
              total_entries: 3
            )
          )
        )
      end
    end
  end

  describe '#make_change!' do
    let(:change) do
      Gitlab::Housekeeper::Change.new.tap do |c|
        c.context = {
          entries_to_check: [
            'spec/controllers/application_controller_spec.rb',
            'spec/models/project_spec.rb'
          ],
          total_entries: 3
        }
      end
    end

    let(:todo_content) do
      <<~YAML
        ---
        - './spec/controllers/application_controller_spec.rb'
        - './spec/models/project_spec.rb'
        - './spec/models/user_spec.rb'
      YAML
    end

    before do
      File.write(todo_yaml_path, todo_content)
      FileUtils.touch(failure_yaml_path)
    end

    context 'when all specs pass order dependency check' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with(check_script, anything).and_return(true)
      end

      it 'removes successful spec files from todo file', :aggregate_failures do
        actual_change = keep.make_change!(change)

        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(change.title).to eq(
          '[RSpec random order] Processed 2 specs: all passed :white_check_mark:'
        )
        expect(change.labels).to match_array(
          ['backend', 'type::maintenance', 'test', 'Engineering Productivity']
        )
        expect(change.changed_files).to match_array([todo_yaml_path])

        # Verify TODO file updated
        yaml_data = YAML.safe_load(File.read(todo_yaml_path))
        expect(yaml_data).to match_array(['./spec/models/user_spec.rb'])

        expect(File).to exist(failure_yaml_path)
      end
    end

    context 'when specs fail order dependency check' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with(check_script, anything)
          .and_raise(::Gitlab::Housekeeper::Shell::Error.new('Order dependency detected'))
      end

      it 'updates failure and TODO files', :aggregate_failures do
        keep.make_change!(change)

        expect(change.title).to eq(
          '[RSpec random order] Processed 2 specs: all failed :x:'
        )
        expect(change.changed_files).to match_array([todo_yaml_path, failure_yaml_path])

        failure_data = YAML.safe_load(File.read(failure_yaml_path))
        expect(failure_data).to match_array([
          './spec/controllers/application_controller_spec.rb',
          './spec/models/project_spec.rb'
        ])

        # Verify TODO file updated
        yaml_data = YAML.safe_load(File.read(todo_yaml_path))
        expect(yaml_data).to match_array(['./spec/models/user_spec.rb'])
      end
    end

    context 'when some specs pass and some fail' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with(check_script, 'spec/controllers/application_controller_spec.rb').and_return(true)
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with(check_script, 'spec/models/project_spec.rb')
          .and_raise(::Gitlab::Housekeeper::Shell::Error.new('Order dependency detected'))
      end

      it 'handles mixed results correctly' do
        keep.make_change!(change)

        expect(change.title).to eq(
          '[RSpec random order] Processed 2 specs: 1 passed :white_check_mark:, 1 failed :x:'
        )

        # Only failing spec should be in failure file
        failure_data = YAML.safe_load(File.read(failure_yaml_path))
        expect(failure_data).to match_array(['./spec/models/project_spec.rb'])
      end
    end
  end
end
