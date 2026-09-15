# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/click_house_idempotent_ddl'

RSpec.describe RuboCop::Cop::Migration::ClickHouseIdempotentDdl, feature_category: :database do
  before do
    allow(cop).to receive(:in_click_house_migration?).and_return(true)
  end

  def msg(statement, guard)
    "ClickHouse migrations must be idempotent. Use `#{statement} #{guard}`."
  end

  describe 'CREATE TABLE' do
    it 'registers an offense and corrects a heredoc' do
      expect_offense(<<~RUBY)
        execute <<~SQL
          CREATE TABLE my_table (id Int64) ENGINE = MergeTree
          ^^^^^^^^^^^^ #{msg('CREATE TABLE', 'IF NOT EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        execute <<~SQL
          CREATE TABLE IF NOT EXISTS my_table (id Int64) ENGINE = MergeTree
        SQL
      RUBY
    end

    it 'registers an offense and corrects a single-quoted string' do
      expect_offense(<<~RUBY)
        execute 'CREATE TABLE my_table (id Int64) ENGINE = MergeTree'
                 ^^^^^^^^^^^^ #{msg('CREATE TABLE', 'IF NOT EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute 'CREATE TABLE IF NOT EXISTS my_table (id Int64) ENGINE = MergeTree'
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        execute <<~SQL
          CREATE TABLE IF NOT EXISTS my_table (id Int64) ENGINE = MergeTree
        SQL
      RUBY
    end
  end

  describe 'DROP TABLE' do
    it 'registers an offense and corrects a heredoc' do
      expect_offense(<<~RUBY)
        execute <<~SQL
          DROP TABLE my_table
          ^^^^^^^^^^ #{msg('DROP TABLE', 'IF EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        execute <<~SQL
          DROP TABLE IF EXISTS my_table
        SQL
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        execute 'DROP TABLE IF EXISTS my_table'
      RUBY
    end
  end

  describe 'CREATE MATERIALIZED VIEW' do
    it 'registers an offense and corrects a heredoc' do
      expect_offense(<<~RUBY)
        execute <<~SQL
          CREATE MATERIALIZED VIEW my_view TO my_table AS SELECT id FROM other
          ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg('CREATE MATERIALIZED VIEW', 'IF NOT EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        execute <<~SQL
          CREATE MATERIALIZED VIEW IF NOT EXISTS my_view TO my_table AS SELECT id FROM other
        SQL
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        execute <<~SQL
          CREATE MATERIALIZED VIEW IF NOT EXISTS my_view TO my_table AS SELECT id FROM other
        SQL
      RUBY
    end
  end

  describe 'DROP VIEW' do
    it 'registers an offense and corrects a double-quoted string' do
      expect_offense(<<~RUBY)
        execute "DROP VIEW my_view"
                 ^^^^^^^^^ #{msg('DROP VIEW', 'IF EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute "DROP VIEW IF EXISTS my_view"
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        execute 'DROP VIEW IF EXISTS my_view'
      RUBY
    end
  end

  describe 'CREATE VIEW' do
    it 'registers an offense and corrects a plain view' do
      expect_offense(<<~RUBY)
        execute 'CREATE VIEW my_view AS SELECT id FROM other'
                 ^^^^^^^^^^^ #{msg('CREATE VIEW', 'IF NOT EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute 'CREATE VIEW IF NOT EXISTS my_view AS SELECT id FROM other'
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        execute 'CREATE VIEW IF NOT EXISTS my_view AS SELECT id FROM other'
      RUBY
    end

    it 'registers no offense for CREATE OR REPLACE VIEW, which is already idempotent' do
      expect_no_offenses(<<~RUBY)
        execute 'CREATE OR REPLACE VIEW my_view AS SELECT id FROM other'
      RUBY
    end

    it 'does not mistake CREATE MATERIALIZED VIEW for a plain view' do
      expect_offense(<<~RUBY)
        execute 'CREATE MATERIALIZED VIEW my_view TO my_table AS SELECT id FROM other'
                 ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg('CREATE MATERIALIZED VIEW', 'IF NOT EXISTS')}
      RUBY
    end
  end

  describe 'word boundaries' do
    it 'registers no offense for identifiers that merely start with a keyword' do
      expect_no_offenses(<<~RUBY)
        execute <<~SQL
          SELECT 'CREATE TABLES', 'DROP VIEWS', 'CREATE DICTIONARIES'
        SQL
      RUBY
    end
  end

  describe 'DICTIONARY' do
    it 'registers an offense and corrects DROP DICTIONARY' do
      expect_offense(<<~RUBY)
        execute('DROP DICTIONARY my_dict')
                 ^^^^^^^^^^^^^^^ #{msg('DROP DICTIONARY', 'IF EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute('DROP DICTIONARY IF EXISTS my_dict')
      RUBY
    end

    it 'registers an offense and corrects CREATE DICTIONARY' do
      expect_offense(<<~RUBY)
        definition = <<~SQL
          CREATE DICTIONARY my_dict (`id` UInt64) PRIMARY KEY id SOURCE(CLICKHOUSE())
          ^^^^^^^^^^^^^^^^^ #{msg('CREATE DICTIONARY', 'IF NOT EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        definition = <<~SQL
          CREATE DICTIONARY IF NOT EXISTS my_dict (`id` UInt64) PRIMARY KEY id SOURCE(CLICKHOUSE())
        SQL
      RUBY
    end

    it 'registers no offense when guarded' do
      expect_no_offenses(<<~RUBY)
        definition = <<~SQL
          CREATE DICTIONARY IF NOT EXISTS my_dict (`id` UInt64) PRIMARY KEY id
        SQL
        execute('DROP DICTIONARY IF EXISTS my_dict')
      RUBY
    end
  end

  context 'with a non-squiggly heredoc' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        execute <<-SQL
          DROP TABLE my_table
          ^^^^^^^^^^ #{msg('DROP TABLE', 'IF EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        execute <<-SQL
          DROP TABLE IF EXISTS my_table
        SQL
      RUBY
    end
  end

  context 'with string interpolation' do
    it 'registers a single offense for an interpolated heredoc' do
      expect_offense(<<~'RUBY', msg: msg('DROP TABLE', 'IF EXISTS'))
        execute <<~SQL
          DROP TABLE #{TABLE_NAME}
          ^^^^^^^^^^ %{msg}
        SQL
      RUBY

      expect_correction(<<~'RUBY')
        execute <<~SQL
          DROP TABLE IF EXISTS #{TABLE_NAME}
        SQL
      RUBY
    end

    it 'registers no offense when the guarded statement is interpolated' do
      expect_no_offenses(<<~'RUBY')
        execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME}
          (#{COLUMNS})
          #{TABLE_OPTIONS}
        SQL
      RUBY
    end
  end

  context 'with several statements in one heredoc' do
    it 'registers an offense per statement' do
      expect_offense(<<~RUBY)
        execute <<~SQL
          DROP VIEW my_view;
          ^^^^^^^^^ #{msg('DROP VIEW', 'IF EXISTS')}
          DROP TABLE my_table;
          ^^^^^^^^^^ #{msg('DROP TABLE', 'IF EXISTS')}
        SQL
      RUBY

      expect_correction(<<~RUBY)
        execute <<~SQL
          DROP VIEW IF EXISTS my_view;
          DROP TABLE IF EXISTS my_table;
        SQL
      RUBY
    end
  end

  context 'when the SQL is not lexically attached to execute' do
    it 'registers an offense on a heredoc returned from a helper' do
      expect_offense(<<~RUBY)
        def create_table_sql
          <<~SQL
            CREATE TABLE my_table (id Int64) ENGINE = MergeTree
            ^^^^^^^^^^^^ #{msg('CREATE TABLE', 'IF NOT EXISTS')}
          SQL
        end
      RUBY
    end
  end

  context 'with the wrong guard' do
    it 'registers an offense and corrects CREATE TABLE IF EXISTS' do
      expect_offense(<<~RUBY)
        execute 'CREATE TABLE IF EXISTS my_table'
                 ^^^^^^^^^^^^^^^^^^^^^^ #{msg('CREATE TABLE', 'IF NOT EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute 'CREATE TABLE IF NOT EXISTS my_table'
      RUBY
    end

    it 'registers an offense and corrects DROP TABLE IF NOT EXISTS' do
      expect_offense(<<~RUBY)
        execute 'DROP TABLE IF NOT EXISTS my_table'
                 ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg('DROP TABLE', 'IF EXISTS')}
      RUBY

      expect_correction(<<~RUBY)
        execute 'DROP TABLE IF EXISTS my_table'
      RUBY
    end
  end

  it 'registers no offense for a Ruby comment mentioning DDL' do
    expect_no_offenses(<<~RUBY)
      # Using `CREATE TABLE ... AS source_table` keeps the tmp table in sync, then
      # we DROP TABLE the original.
      def up; end
    RUBY
  end

  it 'registers no offense for unrelated DDL' do
    expect_no_offenses(<<~RUBY)
      execute <<~SQL
        ALTER TABLE my_table ADD COLUMN foo String
      SQL
    RUBY
  end

  describe 'path scoping' do
    let(:source) { "execute 'DROP TABLE my_table'\n" }

    before do
      allow(cop).to receive(:in_click_house_migration?).and_call_original
    end

    %w[
      db/click_house/migrate/main/20260101000000_create_foo.rb
      db/click_house/post_migrate/main/20260101000000_create_foo.rb
    ].each do |path|
      it "registers an offense in #{path}" do
        expect_offense(<<~RUBY, path)
          execute 'DROP TABLE my_table'
                   ^^^^^^^^^^ #{msg('DROP TABLE', 'IF EXISTS')}
        RUBY
      end
    end

    %w[
      gems/gitlab-active-context/lib/active_context/databases/postgresql/executor.rb
      db/migrate/20260101000000_create_foo.rb
      db/post_migrate/20260101000000_create_foo.rb
      app/models/foo.rb
    ].each do |path|
      it "registers no offense in #{path}" do
        expect_no_offenses(source, path)
      end
    end
  end
end
