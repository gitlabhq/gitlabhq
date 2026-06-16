# frozen_string_literal: true

require 'fast_spec_helper'
require './keeps/helpers/grafana_unused_index_query'

RSpec.describe Keeps::Helpers::GrafanaUnusedIndexQuery, feature_category: :database do
  let(:api_url) { 'https://dashboards.example.test' }
  let(:api_key) { 'fake-token' }
  let(:datasource_uid) { 'mimir-gitlab-gprd' }
  let(:grafana_client) { instance_double(Grafana::Client) }

  subject(:query) { described_class.new }

  before do
    stub_env('GITLAB_GRAFANA_API_URL', api_url)
    stub_env('GITLAB_GRAFANA_API_KEY', api_key)
    stub_env('GITLAB_GRAFANA_DATASOURCE_UID', datasource_uid)
    allow(Grafana::Client).to receive(:new).with(api_url: api_url, token: api_key).and_return(grafana_client)
  end

  def stub_response(indexrelnames)
    series = indexrelnames.map { |name| { metric: { indexrelname: name }, value: [1, '0'] } }
    body = { status: 'success', data: { resultType: 'vector', result: series } }.to_json
    instance_double(HTTParty::Response, body: body)
  end

  describe '#available?' do
    it 'returns true when all env vars are set' do
      expect(query).to be_available
    end

    it 'returns false when API URL is missing' do
      stub_env('GITLAB_GRAFANA_API_URL', '')
      expect(described_class.new).not_to be_available
    end

    it 'returns false when API key is missing' do
      stub_env('GITLAB_GRAFANA_API_KEY', '')
      expect(described_class.new).not_to be_available
    end

    it 'returns false when datasource UID is missing' do
      stub_env('GITLAB_GRAFANA_DATASOURCE_UID', '')
      expect(described_class.new).not_to be_available
    end
  end

  describe '#unused?' do
    before do
      allow(grafana_client).to receive(:proxy_datasource)
        .and_return(stub_response(%w[idle_idx_1 idle_idx_2]))
    end

    it 'returns true when the index is in the zero-activity result set' do
      expect(query.unused?(table: 'users', type: 'patroni', indexrelname: 'idle_idx_1')).to be(true)
    end

    it 'returns false when the index is not in the zero-activity result set' do
      expect(query.unused?(table: 'users', type: 'patroni', indexrelname: 'hot_idx')).to be(false)
    end

    it 'issues one HTTP request per (table, type) pair and caches' do
      query.unused?(table: 'users', type: 'patroni', indexrelname: 'idle_idx_1')
      query.unused?(table: 'users', type: 'patroni', indexrelname: 'idle_idx_2')
      query.unused?(table: 'users', type: 'patroni', indexrelname: 'hot_idx')

      expect(grafana_client).to have_received(:proxy_datasource).once
    end

    it 'issues a separate request for a different table' do
      query.unused?(table: 'users', type: 'patroni', indexrelname: 'idle_idx_1')
      query.unused?(table: 'projects', type: 'patroni', indexrelname: 'idle_idx_1')

      expect(grafana_client).to have_received(:proxy_datasource).twice
    end

    it 'queries with the expected PromQL shape (per-table, cluster-scoped, == 0)' do
      query.unused?(table: 'users', type: 'patroni-ci', indexrelname: 'idle_idx_1')

      expect(grafana_client).to have_received(:proxy_datasource).with(
        hash_including(
          datasource_id: "uid/#{datasource_uid}",
          proxy_path: 'api/v1/query',
          query: hash_including(
            query: a_string_matching(
              %r{
                increase\(
                pg_stat_user_indexes_idx_scan\{
                .*env="gprd".*
                type="patroni-ci".*
                relname="users".*
                \}\[10d\]\)
                .*==\s*0
              }mx
            )
          )
        )
      )
    end

    it 'uses GITLAB_GRAFANA_ENV to override the env= label when set' do
      stub_env('GITLAB_GRAFANA_ENV', 'gstg')
      described_class.new.unused?(table: 'users', type: 'patroni', indexrelname: 'idle_idx_1')

      expect(grafana_client).to have_received(:proxy_datasource).with(
        hash_including(
          query: hash_including(query: a_string_matching(/env="gstg"/))
        )
      )
    end

    it 'escapes backslash and double-quote in interpolated label values' do
      query.unused?(table: 'oddball"name', type: 'cluster\\with\\slash', indexrelname: 'whatever')

      expect(grafana_client).to have_received(:proxy_datasource).with(
        hash_including(
          query: hash_including(
            query: a_string_matching(/type="cluster\\\\with\\\\slash".*relname="oddball\\"name"/m)
          )
        )
      )
    end
  end

  describe 'error handling' do
    it 'returns nil for every lookup when Grafana raises', :aggregate_failures do
      allow(grafana_client).to receive(:proxy_datasource).and_raise(Grafana::Client::Error, 'boom')

      expect do
        expect(query.unused?(table: 'users', type: 'patroni', indexrelname: 'x')).to be_nil
      end.to output(%r{request failed for users/patroni}).to_stderr
    end

    it 'returns nil when the response is not "success"' do
      response = instance_double(HTTParty::Response, body: { status: 'error' }.to_json)
      allow(grafana_client).to receive(:proxy_datasource).and_return(response)

      expect(query.unused?(table: 'users', type: 'patroni', indexrelname: 'x')).to be_nil
    end
  end
end
