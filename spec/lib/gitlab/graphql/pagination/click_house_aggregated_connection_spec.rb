# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::ClickHouseAggregatedConnection, :click_house, :freeze_time, feature_category: :fleet_visibility do
  include GraphqlHelpers
  include_context 'with CI job analytics test data', with_pipelines: false

  let(:clickhouse_connection) { ClickHouse::Connection.new(:main) }
  let(:context_values) { { connection: clickhouse_connection } }
  let(:context) { GraphQL::Query::Context.new(query: query_double, values: context_values) }
  let(:arguments) { {} }
  let(:table) { Arel::Table.new(:ci_finished_builds) }

  let(:mean_duration_in_seconds) do
    duration_function = Arel::Nodes::NamedFunction.new(
      'avg',
      [table[:duration]]
    )

    Arel::Nodes::NamedFunction.new(
      'round',
      [
        Arel::Nodes::Division.new(
          duration_function,
          Arel::Nodes.build_quoted(1000.0)),
        2
      ]
    ).as('mean_duration_in_seconds')
  end

  # query builder that groups by name and calculates mean duration
  let(:aggregated_query_builder) do
    ClickHouse::Client::QueryBuilder
      .new('ci_finished_builds')
      .select(:name)
      .select(mean_duration_in_seconds)
      .where(project_id: project.id)
      .group(:name)
      .order(Arel.sql('mean_duration_in_seconds'), :desc)
  end

  # Wrap the query builder in the aggregated relation
  let(:aggregated_relation) do
    Gitlab::Graphql::Pagination::ClickHouseAggregatedRelation.new(aggregated_query_builder)
  end

  subject(:connection) do
    described_class.new(aggregated_relation, **{ context: context, max_page_size: 3 }.merge(arguments))
  end

  describe '#nodes' do
    let(:expected_results) do
      [
        { 'name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0 },
        { 'name' => 'rspec', 'mean_duration_in_seconds' => 2.67 },
        { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 }
      ]
    end

    subject(:nodes) { connection.nodes }

    it 'returns aggregated results for the first page', :aggregate_failures do
      expect(nodes).to eq(expected_results)

      expect(connection.has_previous_page).to be_falsey
      expect(connection.has_next_page).to be_truthy
    end

    context 'when the first argument is given', :aggregate_failures do
      let(:arguments) { { first: 2 } }

      it 'returns limited results for the first page' do
        expect(nodes.size).to eq(2)
        expect(nodes.pluck('name')).to eq(%w[compile-slow rspec])

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when the last argument is given', :aggregate_failures do
      let(:arguments) { { last: 2 } }

      it 'returns the last results' do
        expect(nodes.size).to eq(2)
        expect(nodes.pluck('name')).to eq(%w[compile lint])

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_falsey
      end
    end

    context 'when after cursor is provided', :aggregate_failures do
      let(:cursor_node) { { 'name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0 } }
      let(:arguments) { { after: encoded_cursor(cursor_node) } }

      it 'returns results after the cursor' do
        expect(nodes.pluck('name')).to contain_exactly('rspec', 'compile', 'lint')

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_falsey
      end
    end

    context 'when before cursor is provided', :aggregate_failures do
      let(:cursor_node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }
      let(:arguments) { { before: encoded_cursor(cursor_node) } }

      it 'returns results before the cursor' do
        expect(nodes.pluck('name')).to contain_exactly('compile-slow', 'rspec')

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when both after and before cursors are provided', :aggregate_failures do
      let(:after_node) { { 'name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0 } }
      let(:before_node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }
      let(:arguments) do
        {
          after: encoded_cursor(after_node),
          before: encoded_cursor(before_node)
        }
      end

      it 'returns results between the cursors' do
        expect(nodes.size).to eq(1)
        expect(nodes.pluck('name')).to contain_exactly('rspec')

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when before and last are provided', :aggregate_failures do
      let(:before_node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }
      let(:arguments) { { last: 1, before: encoded_cursor(before_node) } }

      it 'returns the last N results before the cursor' do
        expect(nodes.size).to eq(1)
        expect(nodes.pluck('name')).to contain_exactly('rspec')

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when before and first are provided', :aggregate_failures do
      let(:before_node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }
      let(:arguments) { { first: 1, before: encoded_cursor(before_node) } }

      it 'returns the first N results before the cursor' do
        expect(nodes.size).to eq(1)
        expect(nodes.pluck('name')).to contain_exactly('rspec')

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'with invalid cursor' do
      let(:arguments) { { after: 'invalid_cursor' } }

      it 'raises an error' do
        expect { nodes }.to raise_error(GraphQL::ExecutionError, /Invalid input: "invalid_cursor"/)
      end
    end

    context 'with malformed cursor' do
      let(:arguments) { { after: Base64.urlsafe_encode64('not_json') } }

      it 'raises an error' do
        expect { nodes }.to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Invalid cursor/)
      end
    end
  end

  describe '#has_previous_page' do
    subject(:has_previous_page) { connection.has_previous_page }

    context 'when after cursor is provided' do
      let(:cursor_node) { { 'name' => 'compile-slow', 'mean_duration_in_seconds' => 5.0 } }
      let(:arguments) { { after: encoded_cursor(cursor_node) } }

      it { is_expected.to be_truthy }
    end

    context 'when last is provided' do
      let(:arguments) { { last: 2 } }

      it { is_expected.to be_truthy }
    end

    context 'when on first page' do
      let(:arguments) { { first: 2 } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_next_page' do
    subject(:has_next_page) { connection.has_next_page }

    context 'when before cursor is provided' do
      let(:cursor_node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }
      let(:arguments) { { before: encoded_cursor(cursor_node) } }

      it { is_expected.to be_truthy }
    end

    context 'when first is provided and there are more results' do
      let(:arguments) { { first: 2 } }

      it { is_expected.to be_truthy }
    end

    context 'when on last page' do
      let(:arguments) { { last: 2 } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#cursor_for' do
    let(:node) { { 'name' => 'compile', 'mean_duration_in_seconds' => 1.0 } }

    subject(:cursor_for) do
      decoded_cursor(connection.cursor_for(node))
    end

    it 'generates a valid cursor' do
      is_expected.to eq(
        'sort_field' => 'mean_duration_in_seconds',
        'sort_value' => 1.0,
        'group_by_values' => { 'name' => 'compile' }
      )
    end

    it 'excludes sort field from group_by_values' do
      expect(cursor_for['group_by_values']).not_to have_key('mean_duration_in_seconds')
    end
  end

  describe '#extract_group_by_fields' do
    subject(:extract_group_by_fields) { connection.send(:extract_group_by_fields) }

    context 'with arel attributes' do
      it { is_expected.to contain_exactly('name') }
    end

    context 'with table attribute' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(table[:name], table[:stage_id])
          .select(mean_duration_in_seconds)
          .where(project_id: project.id)
          .group(table[:name], table[:stage_id])
          .order(Arel.sql('mean_duration_in_seconds'), :desc)
      end

      it { is_expected.to contain_exactly('name', 'stage_id') }
    end
  end

  describe 'pagination with grouped and aggregated data' do
    let(:nodes) { connection.nodes }

    context 'with multiple group by fields' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name, :stage_id)
          .select(mean_duration_in_seconds)
          .where(project_id: project.id)
          .group(:name, :stage_id)
          .order(Arel.sql('mean_duration_in_seconds'), :desc)
      end

      it 'handles multiple group by fields correctly' do
        expect(nodes).not_to be_empty
        expect(nodes.first.keys).to contain_exactly('name', 'stage_id', 'mean_duration_in_seconds')
      end

      it 'generates cursors with all group by values' do
        cursor = connection.cursor_for(nodes.last)
        decoded = decoded_cursor(cursor)

        expect(decoded['group_by_values'].keys).to contain_exactly('name', 'stage_id')
      end
    end

    context 'with ascending order' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name)
          .select(mean_duration_in_seconds)
          .where(project_id: project.id)
          .group(:name)
          .order(Arel.sql('mean_duration_in_seconds'), :asc)
      end

      it 'handles ascending order correctly' do
        durations = nodes.pluck('mean_duration_in_seconds')
        expect(durations).to eq(durations.sort)
      end

      context 'when cursor is provided' do
        let(:cursor_node) { nodes.first }
        let(:second_page_nodes) do
          described_class.new(
            aggregated_relation,
            context: context,
            after: connection.cursor_for(cursor_node)
          ).nodes
        end

        it 'paginate second page with ascending order' do
          expect(second_page_nodes.first['mean_duration_in_seconds']).to be > cursor_node['mean_duration_in_seconds']
        end
      end
    end

    context 'with non-aggregated sort field' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name)
          .select(mean_duration_in_seconds)
          .where(project_id: project.id)
          .group(:name)
          .order(:name, :asc)
      end

      it 'handles non-aggregated sort fields' do
        names = nodes.pluck('name')
        expect(names).to eq(names.sort)
      end

      it 'generates correct cursors for non-aggregated sort' do
        cursor = connection.cursor_for(nodes.first)

        expect(decoded_cursor(cursor)).to eq(
          { 'sort_field' => 'name', 'sort_value' => nodes.first['name'], 'group_by_values' => {} }
        )
      end
    end
  end

  describe 'edge cases and error handling' do
    let(:nodes) { connection.nodes }

    context 'with empty results' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name)
          .select(mean_duration_in_seconds)
          .where(project_id: non_existing_record_id)
          .group(:name)
          .order(Arel.sql('mean_duration_in_seconds'), :desc)
      end

      it 'handles empty results gracefully', :aggregate_failures do
        expect(nodes).to be_empty
        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_falsey
      end
    end

    context 'with cursor for non-existent sort field' do
      let(:invalid_cursor_data) do
        {
          'sort_field' => 'non_existent_field',
          'sort_value' => 1.0,
          'group_by_values' => { 'name' => 'compile' }
        }
      end

      let(:invalid_cursor) { Base64.urlsafe_encode64(Gitlab::Json.dump(invalid_cursor_data)) }
      let(:arguments) { { after: invalid_cursor } }

      it 'handles invalid sort field gracefully' do
        expect { nodes }.not_to raise_error
      end
    end

    context 'with max_page_size limit' do
      let(:arguments) { { first: 100 } }

      it 'respects max_page_size limit' do
        expect(nodes.size).to be <= 3 # max_page_size is 3
      end
    end

    context 'with no order field' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name)
          .select(mean_duration_in_seconds)
          .where(project_id: project.id)
          .group(:name)
      end

      it 'paginates with grouped attribute', :aggregate_failures do
        expect(nodes).to be_present
        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
        expect(connection.cursor_for(nodes.first)).not_to be_nil
        expect(connection.cursor_for(nodes.last)).not_to be_nil

        result = nodes.pluck('name')
        expect(result.sort).to eq(result)
      end
    end
  end

  describe 'stable ordering' do
    let(:build_count) do
      Arel::Nodes::NamedFunction.new(
        'count',
        [Arel.sql('*')]
      ).as('build_count')
    end

    context 'when multiple records have the same sort value' do
      let(:aggregated_query_builder) do
        ClickHouse::Client::QueryBuilder
          .new('ci_finished_builds')
          .select(:name, :stage_id)
          .select(build_count)
          .where(project_id: project.id)
          .group(:name, :stage_id)
          .order(Arel.sql('build_count'), :desc)
      end

      let(:first_page) do
        described_class.new(aggregated_relation, context: context, first: 2).nodes
      end

      let(:second_page) do
        cursor = connection.cursor_for(first_page.last)
        described_class.new(aggregated_relation, context: context, after: cursor, first: 2).nodes
      end

      it 'maintains stable ordering using group by fields' do
        expect(first_page.size).to be <= 2

        # Ensure no overlap between pages
        first_page_ids = first_page.map { |n| [n['name'], n['stage_id']] }
        second_page_ids = second_page.map { |n| [n['name'], n['stage_id']] }
        expect(first_page_ids & second_page_ids).to be_empty
      end
    end
  end

  describe 'integration with GraphQL pagination' do
    let(:schema) do
      Class.new(GraphQL::Schema) do
        use Gitlab::Graphql::Pagination::Connections
      end
    end

    it 'integrates with GraphQL pagination system' do
      expect(schema.connections.wrapper_for(aggregated_relation)).to eq(described_class)
    end
  end

  private

  def encoded_cursor(node)
    described_class.new(aggregated_relation, context: context).cursor_for(node)
  end

  def decoded_cursor(cursor)
    Gitlab::Json.parse(Base64.urlsafe_decode64(cursor))
  end
end
