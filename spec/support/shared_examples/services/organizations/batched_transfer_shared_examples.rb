# frozen_string_literal: true

# Shared example for verifying that organization transfer services generate
# the expected number of batched UPDATE queries.
#
# Requires:
#   - include_context 'with transfer batch size of 1' (or manual stub)
#   - let(:execute_service) { service.execute } or equivalent
#   - let(:expected_batch_queries) - a Hash mapping table names (String) to
#     the minimum number of UPDATE queries expected. Example:
#       { 'ci_runners' => 3, 'ci_runner_machines' => 3 }
#
# Example usage:
#   context 'with batched transfers' do
#     include_context 'with transfer batch size of 1'
#
#     let(:execute_service) { service.execute }
#     let(:expected_batch_queries) do
#       { 'ci_runners' => 3, 'ci_runner_machines' => 3, 'ci_runner_taggings' => 3 }
#     end
#
#     it_behaves_like 'generates batched transfer queries'
#   end
#
RSpec.shared_examples 'generates batched transfer queries' do
  it 'generates the expected number of batched UPDATE queries per table' do
    recorder = ActiveRecord::QueryRecorder.new { execute_service }

    expected_batch_queries.each do |table_name, min_count|
      update_queries = recorder.log.select { |q| q.match?(/UPDATE\s+"#{Regexp.escape(table_name)}"/) }

      expect(update_queries.size).to be >= min_count,
        "Expected at least #{min_count} UPDATE queries for '#{table_name}', " \
          "got #{update_queries.size}.\nQueries found:\n#{update_queries.join("\n")}"
    end
  end
end

# Shared example for verifying that organization transfer services generate
# the expected number of batched INSERT (upsert) queries.
#
# Requires:
#   - include_context 'with transfer batch size of 1' (or manual stub)
#   - let(:execute_service) { service.execute } or equivalent
#   - let(:expected_upsert_queries) - a Hash mapping table names (String) to
#     the minimum number of INSERT queries expected. Example:
#       { 'organization_users' => 3 }
#
RSpec.shared_examples 'generates batched upsert queries' do
  it 'generates the expected number of batched INSERT queries per table' do
    recorder = ActiveRecord::QueryRecorder.new { execute_service }

    expected_upsert_queries.each do |table_name, min_count|
      upsert_queries = recorder.log.select { |q| q.include?("INSERT INTO \"#{table_name}\"") }

      expect(upsert_queries.size).to be >= min_count,
        "Expected at least #{min_count} INSERT queries for '#{table_name}', " \
          "got #{upsert_queries.size}.\nQueries found:\n#{upsert_queries.join("\n")}"
    end
  end
end
