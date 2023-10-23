# frozen_string_literal: true

require 'danger'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/change_column_default'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ChangeColumnDefault, feature_category: :tooling do
  subject(:change_column_default) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:comment) { described_class::COMMENT.chomp }
  let(:file_diff) do
    File.read(File.expand_path("../fixtures/change_column_default_migration.txt", __dir__)).split("\n")
  end

  include_context "with dangerfile"

  describe '#add_comment_for_change_column_default' do
    let(:file_lines) { file_diff.map { |line| line.delete_prefix('+').delete_prefix('-') } }
    let(:matching_lines) { [7, 9, 11] }

    before do
      allow(change_column_default).to receive(:project_helper).and_return(fake_project_helper)
      allow(change_column_default.project_helper).to receive(:file_lines).and_return(file_lines)
      allow(change_column_default.helper).to receive(:all_changed_files).and_return([filename])
      allow(change_column_default.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    end

    context 'when column default is changed in a regular migration' do
      let(:filename) { 'db/migrate/change_column_default_migration.rb' }

      it 'adds comment at the correct line' do
        matching_lines.each do |line_number|
          expect(change_column_default).to receive(:markdown).with("\n#{comment}", file: filename, line: line_number)
        end

        change_column_default.add_comment_for_change_column_default
      end
    end

    context 'when column default is changed in a post-deployment migration' do
      let(:filename) { 'db/post_migrate/change_column_default_migration.rb' }

      it 'adds comment at the correct line' do
        matching_lines.each do |line_number|
          expect(change_column_default).to receive(:markdown).with("\n#{comment}", file: filename, line: line_number)
        end

        change_column_default.add_comment_for_change_column_default
      end
    end

    context 'when a regular migration does not change column default' do
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
        expect(change_column_default).not_to receive(:markdown)

        change_column_default.add_comment_for_change_column_default
      end
    end

    context 'when a post-deployment migration does not change column default' do
      let(:filename) { 'db/post_migrate/my_migration.rb' }
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
        expect(change_column_default).not_to receive(:markdown)

        change_column_default.add_comment_for_change_column_default
      end
    end
  end
end
