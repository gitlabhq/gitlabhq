# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExceedQueryLimitHelpers do
  before do
    stub_const('TestQueries', Class.new(ActiveRecord::Base))
    stub_const('TestMatcher', Class.new)

    TestQueries.class_eval do
      self.table_name = 'schema_migrations'

      def self._returning_columns_for_insert(...)
        ['version']
      end
    end

    TestMatcher.class_eval do
      include ExceedQueryLimitHelpers

      def expected
        ActiveRecord::QueryRecorder.new do
          2.times { TestQueries.count }
        end
      end
    end
  end

  describe '#query_recorder_count' do
    context 'when the query recorder skip_cached does not match the matcher skip_cached' do
      let(:recorder) { ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count } }

      it 'raises an ArgumentError' do
        test_matcher = TestMatcher.new

        expect { test_matcher.query_recorder_count(recorder) }.to raise_error(
          ArgumentError, /`skip_cached` value of the compared query recorders does not match/
        )
      end

      context 'when allow_skip_cache_inconsistency is chained' do
        it 'does not raise' do
          test_matcher = TestMatcher.new.allow_skip_cache_inconsistency

          expect(test_matcher.query_recorder_count(recorder)).to eq(recorder.count)
        end
      end
    end

    context 'when the query recorder skip_cached matches the matcher skip_cached' do
      let(:recorder) { ActiveRecord::QueryRecorder.new { TestQueries.count } }

      it 'does not raise' do
        test_matcher = TestMatcher.new

        expect(test_matcher.query_recorder_count(recorder)).to eq(recorder.count)
      end
    end
  end

  describe 'skip_cached consistency in matchers' do
    let(:consistency_error) { [ArgumentError, /`skip_cached` value of the compared query recorders does not match/] }

    describe 'exceed_query_limit' do
      it 'raises when the control recorder does not skip cached queries' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect do
          expect { TestQueries.count }.not_to exceed_query_limit(control)
        end.to raise_error(*consistency_error)
      end

      it 'raises when the actual recorder does not skip cached queries' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }
        actual = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect do
          expect(actual).not_to exceed_query_limit(control)
        end.to raise_error(*consistency_error)
      end

      it 'does not raise when skip_cached matches' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect { TestQueries.count }.not_to exceed_query_limit(control)
      end

      it 'does not raise when the inconsistency is allowed' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect { TestQueries.count }.not_to exceed_query_limit(control).allow_skip_cache_inconsistency
      end

      it 'raises when the inconsistency is allowed but skip_cached values match' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          expect { TestQueries.count }.not_to exceed_query_limit(control).allow_skip_cache_inconsistency
        end.to raise_error(ArgumentError, /Remove the unnecessary\n`\.allow_skip_cache_inconsistency` call/)
      end
    end

    describe 'exceed_all_query_limit' do
      it 'raises when the control recorder skips cached queries' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          expect { TestQueries.count }.not_to exceed_all_query_limit(control)
        end.to raise_error(*consistency_error)
      end

      it 'does not raise when skip_cached matches' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect { TestQueries.count }.not_to exceed_all_query_limit(control)
      end

      it 'does not raise when the inconsistency is allowed' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect { TestQueries.count }.not_to exceed_all_query_limit(control).allow_skip_cache_inconsistency
      end
    end

    describe 'issue_same_number_of_queries_as' do
      it 'raises when the control recorder skips cached queries but the matcher does not' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          expect { TestQueries.count }.to issue_same_number_of_queries_as(control)
        end.to raise_error(*consistency_error)
      end

      it 'raises when the matcher ignores cached queries but the control recorder does not' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect do
          expect { TestQueries.count }.to issue_same_number_of_queries_as(control).ignoring_cached_queries
        end.to raise_error(*consistency_error)
      end

      it 'does not raise when skip_cached matches' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect { TestQueries.count }.to issue_same_number_of_queries_as(control)
      end

      it 'does not raise when the inconsistency is allowed' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          TestQueries.count
        end.to issue_same_number_of_queries_as(control).allow_skip_cache_inconsistency.with_threshold(1)
      end

      it 'raises when the inconsistency is allowed but skip_cached values match' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { TestQueries.count }

        expect do
          expect { TestQueries.count }.to issue_same_number_of_queries_as(control).allow_skip_cache_inconsistency
        end.to raise_error(ArgumentError, /Remove the unnecessary\n`\.allow_skip_cache_inconsistency` call/)
      end
    end

    describe 'match_query_count' do
      it 'raises when the control recorder skips cached queries but the matcher does not' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          expect { TestQueries.count }.to match_query_count(control)
        end.to raise_error(*consistency_error)
      end

      it 'does not raise when skip_cached matches' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect { TestQueries.count }.to match_query_count(control).ignoring_cached_queries
      end

      it 'does not raise when the inconsistency is allowed' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect { TestQueries.count }.to match_query_count(control).allow_skip_cache_inconsistency
      end

      it 'raises when the inconsistency is allowed but skip_cached values match' do
        control = ActiveRecord::QueryRecorder.new { TestQueries.count }

        expect do
          expect do
            TestQueries.count
          end.to match_query_count(control).ignoring_cached_queries.allow_skip_cache_inconsistency
        end.to raise_error(ArgumentError, /Remove the unnecessary\n`\.allow_skip_cache_inconsistency` call/)
      end
    end
  end

  describe '#diff_query_group_message' do
    it 'prints a group helpfully' do
      test_matcher = TestMatcher.new
      suffixes = {
        'WHERE x = z' => [1, 1],
        'WHERE x = y' => [1, 2],
        'LIMIT 1' => [1, 0]
      }

      message = test_matcher.diff_query_group_message('SELECT * FROM foo', suffixes)

      expect(message).to eq(<<~MSG.chomp)
      SELECT * FROM foo...
      -- (expected: 1, got: 1)
         WHERE x = z
      -- (expected: 1, got: 2)
         WHERE x = y
      -- (expected: 1, got: 0)
         LIMIT 1
      MSG
    end
  end

  describe '#diff_query_counts' do
    let(:expected) do
      ActiveRecord::QueryRecorder.new do
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'also foobar and baz').to_a
        TestQueries.count
        TestQueries.first
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'x').update_all(version: 'y')
        TestQueries.where(version: 'foobar').count
        TestQueries.where(version: 'z').delete_all
        Project.where(id: 1).pluck(:title)
      end
    end

    let(:actual) do
      ActiveRecord::QueryRecorder.new do
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'also foobar and baz').to_a
        TestQueries.count
        TestQueries.create!(version: 'x')
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'x').update_all(version: 'y')
        TestQueries.where(version: 'foobar').count
        TestQueries.count
        TestQueries.where(version: 'y').update_all(version: 'z')
        TestQueries.where(version: 'z').delete_all
        Project.where(id: 2).pluck(:title)
      end
    end

    it 'merges two query counts, showing only diffs' do
      test_matcher = TestMatcher.new

      diff = test_matcher.diff_query_counts(
        test_matcher.count_queries(expected),
        test_matcher.count_queries(actual)
      )

      expect(diff).to eq({
        "SELECT \"schema_migrations\".* FROM \"schema_migrations\"" => {
          "ORDER BY \"schema_migrations\".\"version\" ASC LIMIT 1" => [1, 0]
        },
        "SELECT COUNT(*) FROM \"schema_migrations\"" => { "" => [1, 2] },
        "UPDATE \"schema_migrations\"" => {
          "SET \"version\" = 'z' WHERE \"schema_migrations\".\"version\" = 'y'" => [0, 1]
        },
        "SAVEPOINT active_record_1" => { "" => [0, 1] },
        "INSERT INTO \"schema_migrations\" (\"version\")" => {
          "VALUES ('x') RETURNING \"version\"" => [0, 1]
        },
        "RELEASE SAVEPOINT active_record_1" => { "" => [0, 1] }
      })
    end

    it 'can show common queries if so desired' do
      test_matcher = TestMatcher.new.show_common_queries

      diff = test_matcher.diff_query_counts(
        test_matcher.count_queries(expected),
        test_matcher.count_queries(actual)
      )

      expect(diff).to eq({
        "SELECT \"schema_migrations\".* FROM \"schema_migrations\"" => {
          "WHERE \"schema_migrations\".\"version\" = 'foobar'" => [2, 2],
          "WHERE \"schema_migrations\".\"version\" = 'also foobar and baz'" => [1, 1],
          "ORDER BY \"schema_migrations\".\"version\" ASC LIMIT 1" => [1, 0]
        },
        "SELECT COUNT(*) FROM \"schema_migrations\"" => {
          "" => [1, 2],
          "WHERE \"schema_migrations\".\"version\" = 'foobar'" => [1, 1]
        },
        "UPDATE \"schema_migrations\"" => {
          "SET \"version\" = 'y' WHERE \"schema_migrations\".\"version\" = 'x'" => [1, 1],
          "SET \"version\" = 'z' WHERE \"schema_migrations\".\"version\" = 'y'" => [0, 1]
        },
        "DELETE FROM \"schema_migrations\"" => {
          "WHERE \"schema_migrations\".\"version\" = 'z'" => [1, 1]
        },
        "SAVEPOINT active_record_1" => {
          "" => [0, 1]
        },
        "INSERT INTO \"schema_migrations\" (\"version\")" => {
          "VALUES ('x') RETURNING \"version\"" => [0, 1]
        },
        "RELEASE SAVEPOINT active_record_1" => {
          "" => [0, 1]
        },
        "SELECT \"projects\".\"name\" FROM \"projects\"" => {
          "WHERE \"projects\".\"id\" = 1" => [1, 0],
          "WHERE \"projects\".\"id\" = 2" => [0, 1]
        }
      })
    end
  end

  describe '#count_queries' do
    it 'handles queries with suffixes over multiple lines' do
      test_matcher = TestMatcher.new

      recorder = ActiveRecord::QueryRecorder.new do
        TestQueries.find_by(version: %w[foo bar baz].join("\n"))
        TestQueries.find_by(version: %w[foo biz baz].join("\n"))
        TestQueries.find_by(version: %w[foo bar baz].join("\n"))
      end

      recorder.count

      expect(test_matcher.count_queries(recorder)).to eq({
        'SELECT "schema_migrations".* FROM "schema_migrations"' => {
          %(WHERE "schema_migrations"."version" = 'foo\nbar\nbaz' LIMIT 1) => 2,
          %(WHERE "schema_migrations"."version" = 'foo\nbiz\nbaz' LIMIT 1) => 1
        }
      })
    end

    it 'can aggregate queries' do
      test_matcher = TestMatcher.new

      recorder = ActiveRecord::QueryRecorder.new do
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'also foobar and baz').to_a
        TestQueries.count
        TestQueries.create!(version: 'x')
        TestQueries.first
        TestQueries.where(version: 'foobar').to_a
        TestQueries.where(version: 'x').update_all(version: 'y')
        TestQueries.where(version: 'foobar').count
        TestQueries.count
        TestQueries.where(version: 'y').update_all(version: 'z')
        TestQueries.where(version: 'z').delete_all
      end

      recorder.count

      expect(test_matcher.count_queries(recorder)).to eq({
        'SELECT "schema_migrations".* FROM "schema_migrations"' => {
          %q(WHERE "schema_migrations"."version" = 'foobar') => 2,
          %q(WHERE "schema_migrations"."version" = 'also foobar and baz') => 1,
          %q(ORDER BY "schema_migrations"."version" ASC LIMIT 1) => 1
        },
        'SELECT COUNT(*) FROM "schema_migrations"' => {
          "" => 2,
          %q(WHERE "schema_migrations"."version" = 'foobar') => 1
        },
        'SAVEPOINT active_record_1' => { "" => 1 },
        'INSERT INTO "schema_migrations" ("version")' => {
          %q[VALUES ('x') RETURNING "version"] => 1
        },
        'RELEASE SAVEPOINT active_record_1' => { "" => 1 },
        'UPDATE "schema_migrations"' => {
          %q(SET "version" = 'y' WHERE "schema_migrations"."version" = 'x') => 1,
          %q(SET "version" = 'z' WHERE "schema_migrations"."version" = 'y') => 1
        },
        'DELETE FROM "schema_migrations"' => {
          %q(WHERE "schema_migrations"."version" = 'z') => 1
        }
      })
    end
  end

  it 'can count queries' do
    test_matcher = TestMatcher.new
    test_matcher.verify_count do
      TestQueries.where(version: 'foobar').to_a
      TestQueries.where(version: 'also foobar and baz').to_a
      TestQueries.first
      TestQueries.count
    end

    expect(test_matcher.actual_count).to eq(4)
  end

  it 'can select specific queries' do
    test_matcher = TestMatcher.new.for_query(/foobar/)
    test_matcher.verify_count do
      TestQueries.where(version: 'foobar').to_a
      TestQueries.where(version: 'also foobar and baz').to_a
      TestQueries.first
      TestQueries.count
    end

    expect(test_matcher.actual_count).to eq(2)
  end

  it 'can filter specific models' do
    test_matcher = TestMatcher.new.for_model(TestQueries)
    test_matcher.verify_count do
      TestQueries.first
      TestQueries.connection.execute('select 1')
    end

    expect(test_matcher.actual_count).to eq(1)
  end

  it 'can ignore specific queries' do
    test_matcher = TestMatcher.new.ignoring(/foobar/)
    test_matcher.verify_count do
      TestQueries.where(version: 'foobar').to_a
      TestQueries.where(version: 'also foobar and baz').to_a
      TestQueries.first
    end

    expect(test_matcher.actual_count).to eq(1)
  end

  it 'can perform inclusion and exclusion' do
    test_matcher = TestMatcher.new.for_query(/foobar/).ignoring(/baz/)
    test_matcher.verify_count do
      TestQueries.where(version: 'foobar').to_a
      TestQueries.where(version: 'also foobar and baz').to_a
      TestQueries.first
      TestQueries.count
    end

    expect(test_matcher.actual_count).to eq(1)
  end

  it 'does not contain SQL query log annotations' do
    test_matcher = TestMatcher.new
    test_matcher.verify_count do
      2.times { TestQueries.count }
      TestQueries.first
    end

    aggregate_failures do
      expect(test_matcher.log_message)
        .to match(%r{ORDER BY.*#{TestQueries.table_name}.*LIMIT 1})
      expect(test_matcher.log_message)
        .not_to match(%r{/\*.*correlation_id.*\*/})
    end
  end
end
