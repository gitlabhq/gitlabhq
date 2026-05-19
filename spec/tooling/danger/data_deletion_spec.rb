# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/data_deletion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::DataDeletion, feature_category: :database do
  include_context 'with dangerfile'

  subject(:data_deletion) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }

  let(:file_diff) do
    File.read(File.expand_path("../fixtures/#{fixture}", __dir__))
  end

  # New-file fixtures encode the post-MR content as `+` body lines, so we
  # derive `file_lines` from the diff to keep one source of truth.
  let(:file_lines) do
    file_diff.lines.reject { |line| line.start_with?('@@', '+++', '---') }
                   .map { |line| line.chomp.delete_prefix('+') }
  end

  describe 'MIGRATION_FILES_REGEX' do
    let(:regex) { described_class::MIGRATION_FILES_REGEX }

    it 'matches PostgreSQL migration paths' do
      paths = [
        'db/migrate/20250101010101_foo.rb',
        'db/post_migrate/20250101010102_foo.rb',
        'ee/db/migrate/20250101010105_foo.rb',
        'ee/db/post_migrate/20250101010106_foo.rb',
        'ee/db/embedding/migrate/20250101010107_foo.rb',
        'ee/db/embedding/post_migrate/20250101010108_foo.rb',
        'ee/db/geo/migrate/20250101010109_foo.rb',
        'ee/db/geo/post_migrate/20250101010110_foo.rb'
      ]

      expect(paths).to all(match(regex))
    end

    it 'skips non-PostgreSQL migration paths' do
      paths = [
        'db/click_house/migrate/main/20250101010103_foo.rb',
        'db/click_house/post_migrate/main/20250101010104_foo.rb',
        'ee/elastic/migrate/20250101010111_foo.rb',
        'ee/active_context/migrate/20250101010112_foo.rb',
        'app/models/user.rb',
        'spec/migrations/some_spec.rb',
        'doc/development/database/some_doc.md'
      ]

      paths.each { |path| expect(path).not_to match(regex) }
    end
  end

  describe '#check_data_deletion_label' do
    let(:filename) { 'db/migrate/20250101010101_test_migration.rb' }
    let(:mr_labels) { [] }
    let(:fake_git) { instance_double(Danger::DangerfileGitPlugin) }
    let(:fake_diff_file) { instance_double(Git::Diff::DiffFile, patch: file_diff) }

    before do
      allow(data_deletion).to receive(:project_helper).and_return(fake_project_helper)
      allow(fake_project_helper).to receive(:file_lines).with(filename).and_return(file_lines)
      allow(fake_helper).to receive_messages(all_changed_files: [filename], mr_labels: mr_labels, git: fake_git)
      allow(fake_git).to receive(:diff_for_file).with(filename).and_return(fake_diff_file)
    end

    shared_examples 'flags the migration' do
      it 'fails with a message naming the migration and required label' do
        expect(data_deletion).to receive(:fail) do |message|
          expect(message).to include(filename)
          expect(message).to include(described_class::DATA_DELETION_LABEL)
        end

        data_deletion.check_data_deletion_label
      end
    end

    shared_examples 'allows the migration' do
      it 'does not fail' do
        expect(data_deletion).not_to receive(:fail)

        data_deletion.check_data_deletion_label
      end
    end

    context 'when `def up` deletes data and the label is missing' do
      let(:fixture) { 'data_deletion_migration.txt' }

      it_behaves_like 'flags the migration'
    end

    context 'when `def up` deletes data but the data-deletion label is applied' do
      let(:fixture) { 'data_deletion_migration.txt' }
      let(:mr_labels) { [described_class::DATA_DELETION_LABEL] }

      it_behaves_like 'allows the migration'
    end

    context 'when the migration does not delete data' do
      let(:fixture) { 'non_data_deletion_migration.txt' }

      it_behaves_like 'allows the migration'
    end

    context 'when only `def down` contains a deletion (reversibility rollback)' do
      let(:fixture) { 'data_deletion_in_down_migration.txt' }

      it_behaves_like 'allows the migration'
    end

    context 'when `def change` deletes data' do
      let(:fixture) { 'data_deletion_in_change_migration.txt' }

      it_behaves_like 'flags the migration'
    end

    context 'when deletion happens in a private helper called from `def up`' do
      let(:fixture) { 'data_deletion_in_helper_migration.txt' }

      it_behaves_like 'flags the migration'
    end

    context 'when `def up` uses partitioning helpers that drop tables' do
      let(:fixture) { 'data_deletion_partitioning_helpers_migration.txt' }

      it_behaves_like 'flags the migration'
    end

    context 'when the migration file cannot be parsed as Ruby' do
      let(:file_diff) { "@@ -0,0 +1,1 @@\n+    drop_table :users\n" }
      let(:file_lines) { ['this is not valid ruby <<<'] }

      before do
        allow_next_instance_of(Parser::CurrentRuby) do |parser|
          allow(parser).to receive(:parse).and_raise(Parser::SyntaxError.allocate)
        end
      end

      it_behaves_like 'allows the migration'
    end

    context 'when no migration files are changed' do
      let(:filename) { 'app/models/user.rb' }
      let(:file_diff) { '' }

      it_behaves_like 'allows the migration'
    end
  end
end
