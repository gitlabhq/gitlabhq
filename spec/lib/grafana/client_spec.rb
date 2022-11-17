# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grafana::Client do
  let(:grafana_url) { 'https://grafanatest.com/-/grafana-project' }
  let(:token) { 'test-token' }

  subject(:client) { described_class.new(api_url: grafana_url, token: token) }

  shared_examples 'calls grafana api' do
    let!(:grafana_api_request) { stub_grafana_request(grafana_api_url) }

    it 'calls grafana api' do
      subject

      expect(grafana_api_request).to have_been_requested
    end
  end

  shared_examples 'no redirects' do
    let(:redirect_to) { 'https://redirected.example.com' }
    let(:other_url) { 'https://grafana.example.org' }

    let!(:redirected_req_stub) { stub_grafana_request(other_url) }

    let!(:redirect_req_stub) do
      stub_grafana_request(
        grafana_api_url,
        status: 302,
        headers: { location: redirect_to }
      )
    end

    it 'does not follow redirects' do
      expect { subject }.to raise_exception(
        Grafana::Client::Error,
        'Grafana response status code: 302, Message: {}'
      )

      expect(redirect_req_stub).to have_been_requested
      expect(redirected_req_stub).not_to have_been_requested
    end
  end

  shared_examples 'handles exceptions' do
    exceptions = {
      Gitlab::HTTP::Error => 'Error when connecting to Grafana',
      Net::OpenTimeout => 'Connection to Grafana timed out',
      SocketError => 'Received SocketError when trying to connect to Grafana',
      OpenSSL::SSL::SSLError => 'Grafana returned invalid SSL data',
      Errno::ECONNREFUSED => 'Connection refused',
      StandardError => 'Grafana request failed due to StandardError'
    }

    exceptions.each do |exception, message|
      context exception.to_s do
        before do
          stub_request(:get, grafana_api_url).to_raise(exception)
        end

        it do
          expect { subject }
            .to raise_exception(Grafana::Client::Error, message)
        end
      end
    end
  end

  describe '#get_dashboard' do
    let(:grafana_api_url) { 'https://grafanatest.com/-/grafana-project/api/dashboards/uid/FndfgnX' }

    subject do
      client.get_dashboard(uid: 'FndfgnX')
    end

    it_behaves_like 'calls grafana api'
    it_behaves_like 'no redirects'
    it_behaves_like 'handles exceptions'
  end

  describe '#get_datasource' do
    let(:grafana_api_url) { 'https://grafanatest.com/-/grafana-project/api/datasources/name/Test%20Name' }

    subject do
      client.get_datasource(name: 'Test Name')
    end

    it_behaves_like 'calls grafana api'
    it_behaves_like 'no redirects'
    it_behaves_like 'handles exceptions'
  end

  describe '#proxy_datasource' do
    let(:grafana_api_url) do
      'https://grafanatest.com/-/grafana-project/' \
        'api/datasources/proxy/' \
        '1/api/v1/query_range' \
        '?query=rate(relevant_metric)' \
        '&start=1570441248&end=1570444848&step=900'
    end

    subject do
      client.proxy_datasource(
        datasource_id: '1',
        proxy_path: 'api/v1/query_range',
        query: {
          query: 'rate(relevant_metric)',
          start: 1570441248,
          end: 1570444848,
          step: 900
        }
      )
    end

    it_behaves_like 'calls grafana api'
    it_behaves_like 'no redirects'
    it_behaves_like 'handles exceptions'
  end

  private

  def stub_grafana_request(url, body: {}, status: 200, headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      )
  end
end
