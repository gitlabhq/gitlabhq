# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Graphql::VersionFilter::FutureFieldFilter, feature_category: :shared do
  let(:query) do
    format(<<~GRAPHQL, version: version)
    query fetchData {
      name
      futureField @gl_introduced(version: "%{version}")
    }
    GRAPHQL
  end

  subject(:filtered_query) do
    described_class
      .new(GraphQL.parse(query))
      .visit
      .to_query_string
      .encode('UTF-8')
      .strip
  end

  context 'when version is not future' do
    let(:version) { Gitlab.version_info.to_s }

    it 'does not remove any fields' do
      expect(filtered_query).to eq(query.strip)
    end
  end

  context 'when version is in the future' do
    let(:version) do
      current = Gitlab.version_info
      Gitlab::VersionInfo
        .new(current.major, current.minor, current.patch + 1)
        .to_s
    end

    it 'remove any fields' do
      expect(filtered_query).to eq <<~GRAPHQL.strip
      query fetchData {
        name
      }
      GRAPHQL
    end
  end
end
