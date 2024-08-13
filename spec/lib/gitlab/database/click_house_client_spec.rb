# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse::Client', :click_house, feature_category: :database do
  it 'has a ClickHouse database configured' do
    databases = ClickHouse::Client.configuration.databases

    expect(databases).not_to be_empty
  end

  it 'does not return data via `execute` method' do
    result = ClickHouse::Client.execute("SELECT 1 AS value", :main)

    # does not return data, just true if successful. Otherwise error.
    expect(result).to eq(true)
  end

  describe 'data manipulation' do
    describe 'inserting' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project) }

      let_it_be(:author1) { create(:user, developer_of: project) }
      let_it_be(:author2) { create(:user, developer_of: project) }

      let_it_be(:issue1) { create(:issue, project: project) }
      let_it_be(:issue2) { create(:issue, project: project) }
      let_it_be(:merge_request) { create(:merge_request, source_project: project) }

      let_it_be(:event1) { create(:event, :created, target: issue1, author: author1) }
      let_it_be(:event2) { create(:event, :closed, target: issue2, author: author2) }
      let_it_be(:event3) { create(:event, :merged, target: merge_request, author: author1) }

      let(:events) { [event1, event2, event3] }

      def format_row(event)
        path = event.project.reload.project_namespace.traversal_path

        action = Event.actions[event.action]
        [
          event.id,
          "'#{path}'",
          event.author_id,
          event.target_id,
          "'#{event.target_type}'",
          action,
          event.created_at.to_f,
          event.updated_at.to_f
        ].join(',')
      end

      describe 'RSpec hooks' do
        it 'ensures that tables are empty' do
          results = ClickHouse::Client.select('SELECT * FROM events FINAL', :main)
          expect(results).to be_empty
        end

        it 'inserts data from CSV' do
          time = Time.current.utc
          Tempfile.open(['test', '.csv.gz']) do |f|
            csv = "id,path,created_at\n10,1/2/,#{time.to_f}\n20,1/,#{time.to_f}"
            File.binwrite(f.path, ActiveSupport::Gzip.compress(csv))

            ClickHouse::Client.insert_csv('INSERT INTO events (id, path, created_at) FORMAT CSV', File.open(f.path),
              :main)
          end

          results = ClickHouse::Client.select('SELECT id, path, created_at FROM events FINAL ORDER BY id', :main)

          expect(results).to match([
            { 'id' => 10, 'path' => '1/2/', 'created_at' => be_within(0.1.seconds).of(time) },
            { 'id' => 20, 'path' => '1/', 'created_at' => be_within(0.1.seconds).of(time) }
          ])
        end
      end

      it 'inserts and modifies data' do
        insert_query = <<~SQL
        INSERT INTO events
        (id, path, author_id, target_id, target_type, action, created_at, updated_at)
        VALUES
        (#{format_row(event1)}),
        (#{format_row(event2)}),
        (#{format_row(event3)})
        SQL

        ClickHouse::Client.execute(insert_query, :main)

        results = ClickHouse::Client.select('SELECT * FROM events FINAL ORDER BY id', :main)
        expect(results.size).to eq(3)

        last = results.last
        expect(last).to match(a_hash_including(
          'id' => event3.id,
          'author_id' => event3.author_id,
          'created_at' => be_within(0.05).of(event3.created_at),
          'target_type' => event3.target_type
        ))

        delete_query = ClickHouse::Client::Query.new(
          raw_query: 'DELETE FROM events WHERE id = {id:UInt64}',
          placeholders: { id: event3.id }
        )

        ClickHouse::Client.execute(delete_query, :main)

        select_query = ClickHouse::Client::Query.new(
          raw_query: 'SELECT * FROM events FINAL WHERE id = {id:UInt64}',
          placeholders: { id: event3.id }
        )

        results = ClickHouse::Client.select(select_query, :main)
        expect(results).to be_empty

        # Async, lazy deletion
        # Set the `deleted` field to 1 and update the `updated_at` timestamp.
        # Based on the highest version of the given row (updated_at), CH will eventually remove the row.
        # See: https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replacingmergetree#is_deleted
        soft_delete_query = ClickHouse::Client::Query.new(
          raw_query: %{
            INSERT INTO events (id, deleted, updated_at)
            VALUES ({id:UInt64}, 1, {updated_at:DateTime64(6, 'UTC')})
            },
          placeholders: { id: event2.id, updated_at: (event2.updated_at + 2.hours).utc.to_f }
        )

        ClickHouse::Client.execute(soft_delete_query, :main)

        select_query = ClickHouse::Client::Query.new(
          raw_query: 'SELECT * FROM events FINAL WHERE id = {id:UInt64}',
          placeholders: { id: event2.id }
        )

        results = ClickHouse::Client.select(select_query, :main)
        expect(results).to be_empty
      end
    end
  end

  describe 'logging' do
    let(:query_string) { "SELECT * FROM events WHERE id IN (4, 5, 6)" }

    context 'on dev and test environments' do
      it 'logs the un-redacted query' do
        expect(ClickHouse::Client.configuration.logger).to receive(:info).with({
          query: query_string,
          correlation_id: a_kind_of(String)
        })

        ClickHouse::Client.select(query_string, :main)
      end

      it 'has a ClickHouse logger' do
        expect(ClickHouse::Client.configuration.logger).to be_a(ClickHouse::Logger)
      end
    end
  end
end
