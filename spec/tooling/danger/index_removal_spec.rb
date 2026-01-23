# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/index_removal'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::IndexRemoval, feature_category: :database do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:filename) { 'db/migrate/20240101000000_remove_some_index.rb' }

  subject(:index_removal) { fake_danger.new(helper: fake_helper) }

  describe 'MATCH regex' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength -- Parameterized test table readability
    where(:description, :diff_line, :should_match) do
      'matches remove_index'                      | '+    remove_index :users, :email'                                      | true
      'matches remove_concurrent_index'           | '+    remove_concurrent_index :users, :email'                           | true
      'matches remove_concurrent_index_by_name'   | "+    remove_concurrent_index_by_name :users, 'index_users_on_email'"   | true
      'matches DROP INDEX'                        | '+    execute "DROP INDEX index_users_on_email"'                        | true
      'matches DROP INDEX IF EXISTS'              | '+    execute "DROP INDEX IF EXISTS index_users_on_email"'              | true
      'matches DROP INDEX CONCURRENTLY'           | '+    execute "DROP INDEX CONCURRENTLY index_users_on_email"'           | true
      'matches DROP INDEX CONCURRENTLY IF EXISTS' | '+    execute "DROP INDEX CONCURRENTLY IF EXISTS index_users_on_email"' | true
      'does not match add_index'                  | '+    add_index :users, :email'                                         | false
      'does not match add_concurrent_index'       | '+    add_concurrent_index :users, :email'                              | false
      'does not match comment with DROP INDEX'    | '+    # TODO: DROP INDEX index_users_on_email'                          | false
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it(params[:description]) do
        if should_match
          expect(diff_line).to match(described_class::MATCH)
        else
          expect(diff_line).not_to match(described_class::MATCH)
        end
      end
    end
  end

  describe 'method context detection' do
    using RSpec::Parameterized::TableSyntax

    let(:file_lines) { file_content.lines.map(&:chomp) }

    before do
      allow(index_removal).to receive(:project_helper).and_return(fake_project_helper)
      allow(fake_project_helper).to receive(:file_lines).with(filename).and_return(file_lines)
      allow(index_removal.helper).to receive(:changed_lines).with(filename).and_return([diff_line])
    end

    # rubocop:disable Layout/LineLength -- Parameterized test table readability
    where(:description, :method_name, :diff_line, :should_warn) do
      'warns for remove_index in up method'             | 'up'     | '+    remove_index :users, :email'               | true
      'warns for remove_concurrent_index in up method'  | 'up'     | '+    remove_concurrent_index :users, :email'    | true
      'warns for remove_index in change method'         | 'change' | '+    remove_index :users, :email'               | true
      'warns for DROP INDEX in up method'               | 'up'     | '+    execute "DROP INDEX index_users_on_email"' | true
      'ignores remove_index in down method'             | 'down'   | '+    remove_index :users, :email'               | false
      'ignores remove_concurrent_index in down method'  | 'down'   | '+    remove_concurrent_index :users, :email'    | false
      'ignores DROP INDEX in down method'               | 'down'   | '+    execute "DROP INDEX index_users_on_email"' | false
    end
    # rubocop:enable Layout/LineLength

    with_them do
      let(:file_content) do
        <<~RUBY
          class TestMigration < Gitlab::Database::Migration[2.3]
            def #{method_name}
          #{diff_line.delete_prefix('+')}
            end
          end
        RUBY
      end

      it(params[:description]) do
        index_removal_instance = described_class.new(filename, context: index_removal)
        result = index_removal_instance.send(:added_lines_matching, filename, described_class::MATCH)

        if should_warn
          expect(result).to include(diff_line)
        else
          expect(result).to be_empty
        end
      end
    end
  end

  context 'when parser raises syntax error' do
    let(:file_content) do
      <<~RUBY.chomp
        class TestMigration < Gitlab::Database::Migration[2.3]
          def up
            remove_index :users, :email
          end
        end
      RUBY
    end

    let(:file_lines) { file_content.lines.map(&:chomp) }
    let(:diff_line) { '+    remove_index :users, :email' }

    before do
      allow(index_removal).to receive(:project_helper).and_return(fake_project_helper)
      allow(fake_project_helper).to receive(:file_lines).with(filename).and_return(file_lines)
      allow(index_removal.helper).to receive(:changed_lines).with(filename).and_return([diff_line])

      allow_next_instance_of(Parser::CurrentRuby) do |parser|
        allow(parser).to receive(:parse).and_raise(Parser::SyntaxError.allocate)
      end
    end

    it 'returns an empty array gracefully' do
      index_removal_instance = described_class.new(filename, context: index_removal)
      result = index_removal_instance.send(:added_lines_matching, filename, described_class::MATCH)

      expect(result).to be_empty
    end
  end
end
