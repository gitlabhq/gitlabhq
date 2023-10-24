# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/ignored_model_columns'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::IgnoredModelColumns, feature_category: :tooling do
  subject(:ignored_model_columns) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:comment) { described_class::COMMENT.chomp }
  let(:file_diff) do
    File.read(File.expand_path("../fixtures/#{fixture}", __dir__)).split("\n")
  end

  include_context "with dangerfile"

  describe '#add_comment_for_ignored_model_columns' do
    let(:file_lines) { file_diff.map { |line| line.delete_prefix('+').delete_prefix('-') } }

    before do
      allow(ignored_model_columns).to receive(:project_helper).and_return(fake_project_helper)
      allow(ignored_model_columns.project_helper).to receive(:file_lines).and_return(file_lines)
      allow(ignored_model_columns.helper).to receive(:all_changed_files).and_return([filename])
      allow(ignored_model_columns.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    end

    context 'when table column is renamed in a regular migration' do
      let(:filename) { 'db/migrate/rename_my_column_migration.rb' }
      let(:fixture) { 'rename_column_migration.txt' }
      let(:matching_lines) { [7, 11, 15, 19, 23, 27, 31, 35, 39] }

      it 'adds comment at the correct line' do
        matching_lines.each do |line_number|
          expect(ignored_model_columns).to receive(:markdown).with("\n#{comment}", file: filename, line: line_number)
        end

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end

    context 'when table column is renamed in a post migration' do
      let(:filename) { 'db/post_migrate/remove_column_migration.rb' }
      let(:fixture) { 'remove_column_migration.txt' }
      let(:matching_lines) { [7, 8, 16, 24, 32, 40, 48, 56, 64, 72] }

      it 'adds comment at the correct line' do
        matching_lines.each do |line_number|
          expect(ignored_model_columns).to receive(:markdown).with("\n#{comment}", file: filename, line: line_number)
        end

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end

    context 'when table cleanup is performed in a post migration' do
      let(:filename) { 'db/post_migrate/cleanup_conversion_big_int_migration.rb' }
      let(:fixture) { 'cleanup_conversion_migration.txt' }
      let(:matching_lines) { [7, 11, 15, 19, 23, 27, 31, 35, 39] }

      it 'adds comment at the correct line' do
        matching_lines.each do |line_number|
          expect(ignored_model_columns).to receive(:markdown).with("\n#{comment}", file: filename, line: line_number)
        end

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end

    context 'when a regular migration does not rename table column' do
      let(:filename) { 'db/migrate/my_migration.rb' }
      let(:file_diff) do
        [
          "+    undo_cleanup_concurrent_column_rename(:my_table, :old_column, :new_column)",
          "-    cleanup_concurrent_column_rename(:my_table, :new_column, :old_column)"
        ]
      end

      let(:file_lines) do
        [
          '  def up',
          '    undo_cleanup_concurrent_column_rename(:my_table, :old_column, :new_column)',
          '  end'
        ]
      end

      it 'does not add comment' do
        expect(ignored_model_columns).not_to receive(:markdown)

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end

    context 'when a post migration does not remove table column' do
      let(:filename) { 'db/migrate/my_migration.rb' }
      let(:file_diff) do
        [
          "+    add_column(:my_table, :my_column, :type)",
          "-    remove_column(:my_table, :my_column)"
        ]
      end

      let(:file_lines) do
        [
          '  def up',
          '    add_column(:my_table, :my_column, :type)',
          '  end'
        ]
      end

      it 'does not add comment' do
        expect(ignored_model_columns).not_to receive(:markdown)

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end

    context 'when a post migration does not convert table column' do
      let(:filename) { 'db/migrate/my_migration.rb' }
      let(:file_diff) do
        [
          "+    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)",
          "-    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)"
        ]
      end

      let(:file_lines) do
        [
          '  def up',
          '    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)',
          '  end'
        ]
      end

      it 'does not add comment' do
        expect(ignored_model_columns).not_to receive(:markdown)

        ignored_model_columns.add_comment_for_ignored_model_columns
      end
    end
  end
end
