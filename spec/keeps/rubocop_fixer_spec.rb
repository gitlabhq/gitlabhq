# frozen_string_literal: true

require 'tmpdir'
require 'rubocop'
require 'spec_helper'
require './keeps/rubocop_fixer'

RSpec.describe Keeps::RubocopFixer, feature_category: :tooling do
  let(:todo_dir) { Dir.mktmpdir }
  let(:rubocop_fixer) { described_class.new(limit_fixes: 5) }
  let(:rule1_violating_files) do
    %w[
      rule1_violation1.rb
      rule1_violation2.rb
      rule1_violation3.rb
      rule1_violation4.rb
      rule1_violation5.rb
    ]
  end

  let(:rule2_violating_files) do
    %w[
      rule2_violation1.rb
      rule2_violation2.rb
      rule2_violation3.rb
      rule2_violation4.rb
      rule2_violation5.rb
      rule2_violation6.rb
      rule2_violation7.rb
      rule2_violation8.rb
    ]
  end

  let(:rule1_file) { Pathname(todo_dir).join('rule1.yml').to_s }
  let(:rule2_file) { Pathname(todo_dir).join('rule2.yml').to_s }
  let(:not_autocorrectable_file) { Pathname(todo_dir).join('not_autocorrectable.yml').to_s }
  let(:todo_dir_pattern) { Pathname(todo_dir).join('**/*.yml').to_s }

  before do
    stub_const("#{described_class}::RUBOCOP_TODO_DIR_PATTERN", todo_dir_pattern)
    Pathname.new(todo_dir)
    FileUtils.cp('spec/fixtures/keeps/rubocop_todo1.yml', rule1_file)
    FileUtils.cp('spec/fixtures/keeps/rubocop_todo2.yml', rule2_file)
    FileUtils.cp('spec/fixtures/keeps/rubocop_todo_not_autocorrectable.yml', not_autocorrectable_file)
  end

  after do
    FileUtils.remove_entry(todo_dir)
  end

  describe '#each_change' do
    it 'iterates over todo_dir_pattern files' do
      yielded_times = 0

      # Stub out git
      allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
      # Spy on rubocop
      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect).and_call_original

      rubocop_fixer.each_change do |change|
        yielded_times += 1

        expect(change.title).to include("rubocop violations")
        expect(change.description).to include("Fixes")
        expect(change.labels).to include("backend", "type::maintenance", "maintenance::refactor")

        if change.identifiers.include?('RuboCop/FakeRule1')
          # rule1 contained only 5 exclusions and we fixed all of them so we should have deleted the file
          expect(File).not_to exist(rule1_file)

          expect(change.changed_files).to eq([
            rule1_file,
            *rule1_violating_files
          ])

          expect(::Gitlab::Housekeeper::Shell).to have_received(:rubocop_autocorrect)
            .with(rule1_violating_files, anything)
        elsif change.identifiers.include?('RuboCop/FakeRule2')
          # rule2 contained 8 total exclusions and we fixed 5 of them so there should be 3 left
          expect(File).to exist(rule2_file)
          rule2_content = YAML.load_file(rule2_file)
          expect(rule2_content['RuboCop/FakeRule2']['Exclude']).to eq(rule2_violating_files.last(3))

          expect(change.changed_files).to eq([
            rule2_file,
            *rule2_violating_files.first(5)
          ])

          expect(::Gitlab::Housekeeper::Shell).to have_received(:rubocop_autocorrect)
            .with(rule2_violating_files.first(5), anything)
        else
          raise "Unexpected change: #{change.identifiers}"
        end
      end

      expect(yielded_times).to eq(2)
    end

    context 'when rubocop fails to fix the errors' do
      it 'checks out the files' do
        expect(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
          .once
          .with(rule1_violating_files, anything)
          .and_return(false)
        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .once
          .ordered
          .with('git', 'checkout', rule1_file, *rule1_violating_files)

        expect(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
          .once
          .with(rule2_violating_files.first(5), anything)
          .and_return(false)
        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .once
          .with('git', 'checkout', rule2_file, *rule2_violating_files.first(5))

        rubocop_fixer.each_change
      end
    end

    context 'when some rules can be autocorrected and others cannot' do
      it 'only processes rules that can be autocorrected' do
        yielded_times = 0

        # Stub config_helper to return true for rule1 and false for rule2
        allow(rubocop_fixer.send(:config_helper)).to receive(:can_autocorrect?) do |rule|
          rule == 'RuboCop/FakeRule1'
        end

        # Stub out git and rubocop calls
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
        allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect).and_call_original

        expect(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect).once.with(rule1_violating_files, anything)

        rubocop_fixer.each_change do |change|
          yielded_times += 1

          # Should only process rule1, not rule2
          expect(change.identifiers).to include('RuboCop/FakeRule1')
          expect(change.identifiers).not_to include('RuboCop/FakeRule2')
        end

        expect(yielded_times).to eq(1)
      end
    end
  end
end
