# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::ExternalHttp, :request_store do
  subject { described_class.new }

  let(:subscriber) { Gitlab::Metrics::Subscribers::ExternalHttp.new }

  before do
    allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  let(:event_1) do
    double(:event, payload: {
      method: 'POST', code: "200", duration: 0.03,
      scheme: 'https', host: 'gitlab.com', port: 80, path: '/api/v4/projects',
      query: 'current=true'
    })
  end

  let(:event_2) do
    double(:event, payload: {
      method: 'POST', duration: 1.3,
      scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2/issues',
      query: 'current=true',
      exception_object: Net::ReadTimeout.new
    })
  end

  let(:event_3) do
    double(:event, payload: {
      method: 'GET', code: "301", duration: 0.005,
      scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2',
      query: 'current=true',
      proxy_host: 'proxy.gitlab.com', proxy_port: 8080
    })
  end

  it 'returns no results' do
    expect(subject.results).to eq(
      calls: 0, details: [], duration: "0ms", warnings: []
    )
  end

  it 'returns aggregated results' do
    subscriber.request(event_1)
    subscriber.request(event_2)
    subscriber.request(event_3)

    results = subject.results
    expect(results[:calls]).to eq(3)
    expect(results[:duration]).to eq("1335.00ms")
    expect(results[:details].count).to eq(3)

    expected = [
      {
        duration: 30.0,
        label: "POST https://gitlab.com:80/api/v4/projects?current=true",
        code: "Response status: 200",
        proxy: nil,
        error: nil,
        warnings: []
      },
      {
        duration: 1300,
        label: "POST http://gitlab.com:80/api/v4/projects/2/issues?current=true",
        code: nil,
        proxy: nil,
        error: "Exception: Net::ReadTimeout",
        warnings: ["1300.0 over 100"]
      },
      {
        duration: 5.0,
        label: "GET http://gitlab.com:80/api/v4/projects/2?current=true",
        code: "Response status: 301",
        proxy: nil,
        error: nil,
        warnings: []
      }
    ]

    expect(
      results[:details].map { |data| data.slice(:duration, :label, :code, :proxy, :error, :warnings) }
    ).to match_array(expected)
  end
end
