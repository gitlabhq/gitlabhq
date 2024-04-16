# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rspec-profiling spec', feature_category: :tooling do
  let(:expected_headers) do
    # This should match https://github.com/procore-oss/rspec_profiling/blob/45df8d429643c4307fc62fa00d0a593932e6aff5/lib/rspec_profiling/collectors/psql.rb#L28-L40
    %w[branch commit_hash date file line_number description time status
      exception query_count query_time request_count request_time
      created_at updated_at feature_category]
  end

  it 'includes only headers supported by the database' do
    expect(RspecProfilingExt::Collectors::CSVWithTimestamps::HEADERS).to match_array(expected_headers)
  end
end
