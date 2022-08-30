# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Zentao::Client, :clean_gitlab_redis_cache do
  subject(:client) { described_class.new(zentao_integration) }

  let(:zentao_integration) { create(:zentao_integration) }

  def mock_get_products_url
    client.send(:url, "products/#{zentao_integration.zentao_product_xid}")
  end

  def mock_fetch_issues_url
    client.send(:url, "products/#{zentao_integration.zentao_product_xid}/issues")
  end

  def mock_fetch_issue_url(issue_id)
    client.send(:url, "issues/#{issue_id}")
  end

  let(:mock_headers) do
    {
      headers: {
        'Content-Type' => 'application/json',
        'Token' => zentao_integration.api_token
      }
    }
  end

  describe '#new' do
    context 'if integration is nil' do
      let(:zentao_integration) { nil }

      it 'raises ConfigError' do
        expect { client }.to raise_error(described_class::ConfigError)
      end
    end

    context 'integration is provided' do
      it 'is initialized successfully' do
        expect { client }.not_to raise_error
      end
    end
  end

  describe '#fetch_product' do
    context 'with valid product' do
      let(:mock_response) { { 'id' => zentao_integration.zentao_product_xid } }

      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: mock_response.to_json)
      end

      it 'fetches the product' do
        expect(client.fetch_product(zentao_integration.zentao_product_xid)).to eq mock_response
      end
    end

    context 'with invalid product' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 404, body: {}.to_json)
      end

      it 'fetches the empty product' do
        expect do
          client.fetch_product(zentao_integration.zentao_product_xid)
        end.to raise_error(Gitlab::Zentao::Client::RequestError)
      end
    end

    context 'with invalid response' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: '[invalid json}')
      end

      it 'fetches the empty product' do
        expect do
          client.fetch_product(zentao_integration.zentao_product_xid)
        end.to raise_error(Gitlab::Zentao::Client::Error, 'invalid response format')
      end
    end
  end

  describe '#ping' do
    context 'with valid resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '0' }.to_json)
      end

      it 'responds with success' do
        expect(client.ping[:success]).to eq true
      end
    end

    context 'with deleted resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '1' }.to_json)
      end

      it 'responds with unsuccess' do
        expect(client.ping[:success]).to eq false
      end
    end
  end

  describe '#fetch_issues' do
    let(:mock_response) { { 'issues' => [{ 'id' => 'story-1' }, { 'id' => 'bug-11' }] } }

    before do
      WebMock.stub_request(:get, mock_fetch_issues_url)
             .with(mock_headers).to_return(status: 200, body: mock_response.to_json)
    end

    it 'returns the response' do
      expect(client.fetch_issues).to eq(mock_response)
    end

    describe 'marking the issues as seen in the product' do
      let(:cache) { ::Gitlab::SetCache.new }
      let(:cache_key) do
        [
          :zentao_product_issues,
          OpenSSL::Digest::SHA256.hexdigest(zentao_integration.client_url),
          zentao_integration.zentao_product_xid
        ].join(':')
      end

      it 'adds issue ids to the cache' do
        expect { client.fetch_issues }.to change { cache.read(cache_key) }
          .from(be_empty)
          .to match_array(%w[bug-11 story-1])
      end

      it 'does not add issue ids to the cache if max set size has been reached' do
        cache.write(cache_key, %w[foo bar])
        stub_const("#{described_class}::CACHE_MAX_SET_SIZE", 1)

        client.fetch_issues

        expect(cache.read(cache_key)).to match_array(%w[foo bar])
      end

      it 'does not duplicate issue ids in the cache' do
        client.fetch_issues
        client.fetch_issues

        expect(cache.read(cache_key)).to match_array(%w[bug-11 story-1])
      end

      it 'touches the cache ttl every time issues are fetched' do
        fresh_ttl = 1.month.to_i

        freeze_time do
          client.fetch_issues

          expect(cache.ttl(cache_key)).to eq(fresh_ttl)
        end

        travel_to(1.minute.from_now) do
          client.fetch_issues

          expect(cache.ttl(cache_key)).to eq(fresh_ttl)
        end
      end
    end
  end

  describe '#fetch_issue' do
    context 'with invalid id' do
      let(:invalid_ids) { ['story', 'story-', '-', '123', ''] }

      it 'raises Error' do
        invalid_ids.each do |id|
          expect { client.fetch_issue(id) }
            .to raise_error(Gitlab::Zentao::Client::Error, 'invalid issue id')
        end
      end
    end

    context 'with valid id' do
      let(:valid_ids) { %w[story-1 bug-23] }

      context 'when issue has been seen on the index' do
        before do
          issues_body = { issues: valid_ids.map { { id: _1 } } }.to_json

          WebMock.stub_request(:get, mock_fetch_issues_url)
                 .with(mock_headers).to_return(status: 200, body: issues_body)

          client.fetch_issues
        end

        it 'fetches the issue' do
          valid_ids.each do |id|
            WebMock.stub_request(:get, mock_fetch_issue_url(id))
                  .with(mock_headers).to_return(status: 200, body: { issue: { id: id } }.to_json)

            expect(client.fetch_issue(id).dig('issue', 'id')).to eq id
          end
        end
      end

      context 'when issue has not been seen on the index' do
        it 'raises RequestError' do
          valid_ids.each do |id|
            expect { client.fetch_issue(id) }.to raise_error(Gitlab::Zentao::Client::RequestError)
          end
        end
      end
    end
  end

  describe '#url' do
    context 'api url' do
      shared_examples 'joins api_url correctly' do
        it 'verify url' do
          expect(client.send(:url, "products/1").to_s)
            .to eq("https://jihudemo.zentao.net/zentao/api.php/v1/products/1")
        end
      end

      context 'no ends slash' do
        let(:zentao_integration) { create(:zentao_integration, api_url: 'https://jihudemo.zentao.net/zentao') }

        include_examples 'joins api_url correctly'
      end

      context 'ends slash' do
        let(:zentao_integration) { create(:zentao_integration, api_url: 'https://jihudemo.zentao.net/zentao/') }

        include_examples 'joins api_url correctly'
      end
    end

    context 'no api url' do
      let(:zentao_integration) { create(:zentao_integration, url: 'https://jihudemo.zentao.net') }

      it 'joins url correctly' do
        expect(client.send(:url, "products/1").to_s)
          .to eq("https://jihudemo.zentao.net/api.php/v1/products/1")
      end
    end
  end
end
