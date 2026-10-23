# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Jira::HttpClient, feature_category: :integrations do
  let(:site) { 'https://jira.example.com' }
  let(:options) { { site: site, context_path: '', auth_type: :basic, username: 'user', password: 'pass' } }

  subject(:client) { described_class.new(options) }

  describe '#make_request' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_request(:get, %r{\Ahttps://jira\.example\.com(:443)?/rest/api/2/issue/10001}).to_return(status: 200,
        body: '{}')
    end

    it 'sends a relative path to the configured site' do
      expect(client.make_request(:get, '/rest/api/2/issue/10001').response).to be_a(Net::HTTPOK)
    end

    it 'sends an absolute URL on the configured site' do
      expect(client.make_request(:get, "#{site}/rest/api/2/issue/10001").response).to be_a(Net::HTTPOK)
    end

    where(:requested, :requested_origin) do
      [
        ['https://other.example.com/rest/api/2/issue/10001?token=secret', 'https://other.example.com:443'],
        ['http://jira.example.com/rest/api/2/issue/10001', 'http://jira.example.com:80'],
        ['https://jira.example.com:8443/rest/api/2/issue/10001', 'https://jira.example.com:8443'],
        ['//other.example.com/rest/api/2/issue/10001', 'https://other.example.com:443']
      ]
    end

    with_them do
      it 'raises without sending a request and without leaking the query string', :aggregate_failures do
        expect { client.make_request(:get, requested) }
          .to raise_error(described_class::UnexpectedHostError) { |error|
            expect(error.message).to include(requested_origin, 'https://jira.example.com:443')
            expect(error.message).not_to include('secret')
          }

        expect(WebMock).not_to have_requested(:any, /.*/)
      end
    end

    it 'raises without leaking the query string when the URL is invalid', :aggregate_failures do
      expect { client.make_request(:get, "#{site}/rest/%zz?token=secret") }
        .to raise_error(described_class::UnexpectedHostError) { |error|
          expect(error.message).not_to include('token=secret')
        }

      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end
end
