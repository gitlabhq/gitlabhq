# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::GraphqlHelpers do
  describe 'run_graphql!' do
    let(:query) { '{ metadata { version } }' }

    let(:graphql_helper) do
      Class.new do
        include API::Helpers::GraphqlHelpers
      end.new
    end

    context 'when transform function is provided' do
      let(:result) { { 'data' => { 'metadata' => { 'version' => '1.0.0' } } } }

      before do
        allow(GitlabSchema).to receive(:execute).and_return(result)
      end

      it 'returns the expected result' do
        expect(
          graphql_helper.run_graphql!(
            query: query,
            transform: ->(result) { result.dig('data', 'metadata') }
          )
        ).to eq({ 'version' => '1.0.0' })
      end
    end

    context 'when a transform function is not provided' do
      let(:result) { double('result') }

      before do
        allow(GitlabSchema).to receive(:execute).and_return(result)
      end

      it 'returns the expected result' do
        expect(graphql_helper.run_graphql!(query: query)).to eq(result)
      end
    end
  end
end
