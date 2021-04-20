# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::ExternalHttp, :request_store do
  subject { described_class.new }

  let(:subscriber) { Gitlab::Metrics::Subscribers::ExternalHttp.new }

  before do
    allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  around do |example|
    freeze_time { example.run }
  end

  let(:event_1) do
    {
      method: 'POST', code: "200", duration: 0.03,
      scheme: 'https', host: 'gitlab.com', port: 80, path: '/api/v4/projects',
      query: 'current=true'
    }
  end

  let(:event_2) do
    {
      method: 'POST', duration: 1.3,
      scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2/issues',
      query: 'current=true',
      exception_object: Net::ReadTimeout.new
    }
  end

  let(:event_3) do
    {
      method: 'GET', code: "301", duration: 0.005,
      scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2',
      query: 'current=true',
      proxy_host: 'proxy.gitlab.com', proxy_port: 8080
    }
  end

  it 'returns no results' do
    expect(subject.results).to eq(
      calls: 0, details: [], duration: "0ms", warnings: []
    )
  end

  it 'returns aggregated results' do
    subscriber.request(double(:event, payload: event_1, time: Time.current))
    subscriber.request(double(:event, payload: event_2, time: Time.current))
    subscriber.request(double(:event, payload: event_3, time: Time.current))

    results = subject.results
    expect(results[:calls]).to eq(3)
    expect(results[:duration]).to eq("1335.00ms")
    expect(results[:details].count).to eq(3)

    expected = [
      {
        start: be_like_time(Time.current),
        duration: 30.0,
        label: "POST https://gitlab.com:80/api/v4/projects?current=true",
        code: "Response status: 200",
        proxy: nil,
        error: nil,
        warnings: []
      },
      {
        start: be_like_time(Time.current),
        duration: 1300,
        label: "POST http://gitlab.com:80/api/v4/projects/2/issues?current=true",
        code: nil,
        proxy: nil,
        error: "Exception: Net::ReadTimeout",
        warnings: ["1300.0 over 100"]
      },
      {
        start: be_like_time(Time.current),
        duration: 5.0,
        label: "GET http://gitlab.com:80/api/v4/projects/2?current=true",
        code: "Response status: 301",
        proxy: nil,
        error: nil,
        warnings: []
      }
    ]

    expect(
      results[:details].map { |data| data.slice(:start, :duration, :label, :code, :proxy, :error, :warnings) }
    ).to match_array(expected)
  end

  context 'when the host is in IPv4 format' do
    before do
      event_1[:host] = '1.2.3.4'
    end

    it 'displays IPv4 in the label' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST https://1.2.3.4:80/api/v4/projects?current=true",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end

  context 'when the host is in IPv6 foramat' do
    before do
      event_1[:host] = '2606:4700:90:0:f22e:fbec:5bed:a9b9'
    end

    it 'displays IPv6 in the label' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST https://[2606:4700:90:0:f22e:fbec:5bed:a9b9]:80/api/v4/projects?current=true",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end

  context 'when the query is a hash' do
    before do
      event_1[:query] = { current: true, 'item1' => 'string', 'item2' => [1, 2] }
    end

    it 'converts query hash into a query string' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST https://gitlab.com:80/api/v4/projects?current=true&item1=string&item2%5B%5D=1&item2%5B%5D=2",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end

  context 'when the host is invalid' do
    before do
      event_1[:host] = '!@#%!@#%!@#%'
    end

    it 'displays unknown in the label' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST unknown",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end

  context 'when URI creation raises an URI::Error' do
    before do
      # This raises an URI::Error exception
      event_1[:port] = 'invalid'
    end

    it 'displays unknown in the label' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST unknown",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end

  context 'when URI creation raises a StandardError exception' do
    before do
      # This raises a TypeError exception
      event_1[:scheme] = 1234
    end

    it 'displays unknown in the label' do
      subscriber.request(double(:event, payload: event_1, time: Time.current))

      expect(subject.results[:details]).to contain_exactly(
        a_hash_including(
          start: be_like_time(Time.current),
          duration: 30.0,
          label: "POST unknown",
          code: "Response status: 200",
          proxy: nil,
          error: nil,
          warnings: []
        )
      )
    end
  end
end
