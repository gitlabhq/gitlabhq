# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::LogLargeInLists, query_analyzers: false, feature_category: :database do
  let(:analyzer) { described_class }
  let(:fixture) { fixture_file("gitlab/database/query_analyzers/#{file}") }
  let(:sql) { fixture.gsub('%IN_LIST%', arguments) }

  # Reduce the in list size to 5 to help with testing
  # Reduce the min query size to 50 to help with testing
  before do
    stub_const("#{described_class}::MIN_QUERY_SIZE", 50)
    stub_const("#{described_class}::IN_SIZE_LIMIT", 5)
    stub_const("#{described_class}::REGEX", /\bIN\s*\((?:\s*\$?\d+\s*,){4,}\s*\$?\d+\s*\)/i)
    allow(analyzer).to receive(:backtrace).and_return([])
    allow(analyzer).to receive(:suppressed?).and_return(true) # bypass suppressed? method to avoid false positives
  end

  after do
    # Clears analyzers list after each test to reload the state of `enabled?` method
    Thread.current[:query_analyzer_enabled_analyzers] = []
  end

  context 'when feature flag is enabled' do
    before do
      stub_feature_flags(log_large_in_list_queries: true)
      Gitlab::Database::QueryAnalyzer.instance.begin!([analyzer])
    end

    context 'when conditions are satisfied for logging' do
      where(:file, :arguments, :result, :event_name) do
        [
          [
            'small_query_with_in_list.txt',
            '1, 2, 3, 4, 5, 6',
            { message: 'large_in_list_found', matches: 1, in_list_size: "6", stacktrace: [], event_name: 'load' },
            'load'
          ],
          [
            'small_query_with_in_list.txt',
            '1,2,3,4,5,6',
            { message: 'large_in_list_found', matches: 1, in_list_size: "6", stacktrace: [], event_name: 'pluck' },
            'pluck'
          ],
          [
            'small_query_with_in_list.txt',
            'SELECT id FROM projects where id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)',
            { message: 'large_in_list_found', matches: 1, in_list_size: "10", stacktrace: [], event_name: 'load' },
            'load'
          ],
          [
            'large_query_with_in_list.txt',
            '1,2,3,4,5,6',
            { message: 'large_in_list_found', matches: 1, in_list_size: "6", stacktrace: [], event_name: 'load' },
            'load'
          ],
          [
            'large_query_with_in_list.txt',
            '1, 2, 3, 4, 5, 6',
            { message: 'large_in_list_found', matches: 1, in_list_size: "6", stacktrace: [], event_name: 'pluck' },
            'pluck'
          ],
          [
            'large_query_with_in_list.txt',
            'SELECT id FROM projects where id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)',
            { message: 'large_in_list_found', matches: 1, in_list_size: "10", stacktrace: [], event_name: 'load' },
            'load'
          ]
        ]
      end

      with_them do
        it 'logs all the occurrences' do
          expect(Gitlab::AppLogger).to receive(:warn).with(result)

          process_sql(sql, event_name)
        end
      end
    end

    context 'when conditions are not satisfied for logging' do
      where(:file, :arguments, :event_name) do
        [
          ['small_query_with_in_list.txt', '1, 2, 3, 4, 5', 'load'],
          ['small_query_with_in_list.txt', '$1, $2, $3, $4, $5', 'load'],
          ['small_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (1, 2, 3, 4, 5)', 'load'],
          ['small_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (SELECT id FROM namespaces)', 'load'],
          ['small_query_with_in_list.txt', '1, 2, 3, 4, 5', 'schema'],
          ['large_query_with_in_list.txt', '1, 2, 3, 4, 5', 'load'],
          ['large_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (1, 2, 3, 4, 5)', 'load'],
          ['large_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (SELECT id FROM namespaces)', 'load'],
          ['large_query_with_in_list.txt', '1, 2, 3, 4, 5', 'schema'],
          ['small_query_without_in_list.txt', '', 'load'],
          ['small_query_without_in_list.txt', '', 'schema']
        ]
      end

      with_them do
        it 'skips logging the occurrences' do
          expect(Gitlab::AppLogger).not_to receive(:warn)

          process_sql(sql, event_name)
        end
      end
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(log_large_in_list_queries: false)
      Gitlab::Database::QueryAnalyzer.instance.begin!([analyzer])
    end

    where(:file, :arguments, :event_name) do
      [
        ['small_query_with_in_list.txt', '1, 2, 3, 4, 5, 6', 'load'],
        ['small_query_with_in_list.txt', '$1, $2, $3, $4, $5, $6', 'load'],
        ['small_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (1, 2, 3, 4, 5, 6)', 'load'],
        ['small_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (1, 2, 3, 4, 5, 6)', 'load'],
        ['small_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (SELECT id FROM namespaces)', 'load'],
        ['small_query_with_in_list.txt', '1, 2, 3, 4, 5, 6', 'schema'],
        ['large_query_with_in_list.txt', '1, 2, 3, 4, 5, 6', 'load'],
        ['large_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (1, 2, 3, 4, 5, 6, 7, 8)', 'load'],
        ['large_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN ($1, $2, $3, $4, $5, $6, $7)', 'load'],
        ['large_query_with_in_list.txt', 'SELECT id FROM projects WHERE id IN (SELECT id FROM namespaces)', 'load'],
        ['large_query_with_in_list.txt', '1, 2, 3, 4, 5, 6', 'schema'],
        ['small_query_without_in_list.txt', '', 'load'],
        ['small_query_without_in_list.txt', '', 'schema']
      ]
    end

    with_them do
      it 'skips logging the occurrences' do
        expect(Gitlab::AppLogger).not_to receive(:warn)

        process_sql(sql, event_name)
      end
    end
  end

  private

  def process_sql(sql, event_name)
    Gitlab::Database::QueryAnalyzer.instance.within do
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, ActiveRecord::Base.connection, event_name)
    end
  end
end
