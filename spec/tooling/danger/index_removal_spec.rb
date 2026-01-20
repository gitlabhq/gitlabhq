# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/index_removal'

RSpec.describe Tooling::Danger::IndexRemoval, feature_category: :database do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
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
end
