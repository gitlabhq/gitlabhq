# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GraphqlLogger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.now }

  it 'builds a logger once' do
    expect(::Logger).to receive(:new).and_call_original

    subject.info('hello world')
    subject.error('hello again')
  end

  context 'logging a GraphQL query' do
    let(:query) { CachedIntrospectionQuery.query_string }

    it 'logs a query from JSON' do
      analyzer_memo = {
        query_string: query,
        variables: {},
        complexity: 181,
        depth: 0,
        duration_s: 7
      }

      output = subject.format_message('INFO', now, 'test', analyzer_memo)

      data = Gitlab::Json.parse(output)
      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['complexity']).to eq(181)
      expect(data['variables']).to eq({})
      expect(data['depth']).to eq(0)
      expect(data['duration_s']).to eq(7)
    end
  end
end
