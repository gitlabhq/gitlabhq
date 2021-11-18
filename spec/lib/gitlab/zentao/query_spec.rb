# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Zentao::Query do
  let(:zentao_integration) { create(:zentao_integration) }
  let(:params) { {} }

  subject(:query) { described_class.new(zentao_integration, ActionController::Parameters.new(params)) }

  describe '#issues' do
    let(:response) { { 'page' => 1, 'total' => 0, 'limit' => 20, 'issues' => [] } }

    def expect_query_option_include(expected_params)
      expect_next_instance_of(Gitlab::Zentao::Client) do |client|
        expect(client).to receive(:fetch_issues)
          .with(hash_including(expected_params))
          .and_return(response)
      end

      query.issues
    end

    context 'when params are empty' do
      it 'fills default params' do
        expect_query_option_include(status: 'opened', order: 'lastEditedDate_desc', labels: '')
      end
    end

    context 'when params contain valid options' do
      let(:params) { { state: 'closed', sort: 'created_asc', labels: %w[Bugs Features] } }

      it 'fills params with standard of ZenTao' do
        expect_query_option_include(status: 'closed', order: 'openedDate_asc', labels: 'Bugs,Features')
      end
    end

    context 'when params contain invalid options' do
      let(:params) { { state: 'xxx', sort: 'xxx', labels: %w[xxx] } }

      it 'fills default params with standard of ZenTao' do
        expect_query_option_include(status: 'opened', order: 'lastEditedDate_desc', labels: 'xxx')
      end
    end
  end

  describe '#issue' do
    let(:response) { { 'issue' => { 'id' => 'story-1' } } }

    before do
      expect_next_instance_of(Gitlab::Zentao::Client) do |client|
        expect(client).to receive(:fetch_issue)
          .and_return(response)
      end
    end

    it 'returns issue object by client' do
      expect(query.issue).to include('id' => 'story-1')
    end
  end
end
