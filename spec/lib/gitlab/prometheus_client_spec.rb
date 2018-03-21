require 'spec_helper'

describe Gitlab::PrometheusClient do
  include PrometheusHelpers

  subject { described_class.new(RestClient::Resource.new('https://prometheus.example.com')) }

  describe '#ping' do
    it 'issues a "query" request to the API endpoint' do
      req_stub = stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector'))

      expect(subject.ping).to eq({ "resultType" => "vector", "result" => [{ "metric" => {}, "value" => [1488772511.004, "0.000041021495238095323"] }] })
      expect(req_stub).to have_been_requested
    end
  end

  # This shared examples expect:
  # - query_url: A query URL
  # - execute_query: A query call
  shared_examples 'failure response' do
    context 'when request returns 400 with an error message' do
      it 'raises a Gitlab::PrometheusClient::Error error' do
        req_stub = stub_prometheus_request(query_url, status: 400, body: { error: 'bar!' })

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::Error, 'bar!')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns 400 without an error message' do
      it 'raises a Gitlab::PrometheusClient::Error error' do
        req_stub = stub_prometheus_request(query_url, status: 400)

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::Error, 'Bad data received')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns 500' do
      it 'raises a Gitlab::PrometheusClient::Error error' do
        req_stub = stub_prometheus_request(query_url, status: 500, body: { message: 'FAIL!' })

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::Error, '500 - {"message":"FAIL!"}')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns non json data' do
      it 'raises a Gitlab::PrometheusClient::Error error' do
        req_stub = stub_prometheus_request(query_url, status: 200, body: 'not json')

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::Error, 'Parsing response failed')
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe 'failure to reach a provided prometheus url' do
    let(:prometheus_url) {"https://prometheus.invalid.example.com"}

    subject { described_class.new(RestClient::Resource.new(prometheus_url)) }

    context 'exceptions are raised' do
      it 'raises a Gitlab::PrometheusClient::Error error when a SocketError is rescued' do
        req_stub = stub_prometheus_request_with_exception(prometheus_url, SocketError)

        expect { subject.send(:get, '/', {}) }
          .to raise_error(Gitlab::PrometheusClient::Error, "Can't connect to #{prometheus_url}")
        expect(req_stub).to have_been_requested
      end

      it 'raises a Gitlab::PrometheusClient::Error error when a SSLError is rescued' do
        req_stub = stub_prometheus_request_with_exception(prometheus_url, OpenSSL::SSL::SSLError)

        expect { subject.send(:get, '/', {}) }
          .to raise_error(Gitlab::PrometheusClient::Error, "#{prometheus_url} contains invalid SSL data")
        expect(req_stub).to have_been_requested
      end

      it 'raises a Gitlab::PrometheusClient::Error error when a RestClient::Exception is rescued' do
        req_stub = stub_prometheus_request_with_exception(prometheus_url, RestClient::Exception)

        expect { subject.send(:get, '/', {}) }
          .to raise_error(Gitlab::PrometheusClient::Error, "Network connection error")
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe '#query' do
    let(:prometheus_query) { prometheus_cpu_query('env-slug') }
    let(:query_url) { prometheus_query_with_time_url(prometheus_query, Time.now.utc) }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'when request returns vector results' do
      it 'returns data from the API call' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_value_body('vector'))

        expect(subject.query(prometheus_query)).to eq [{ "metric" => {}, "value" => [1488772511.004, "0.000041021495238095323"] }]
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns matrix results' do
      it 'returns nil' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_value_body('matrix'))

        expect(subject.query(prometheus_query)).to be_nil
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns no data' do
      it 'returns []' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_empty_body('vector'))

        expect(subject.query(prometheus_query)).to be_empty
        expect(req_stub).to have_been_requested
      end
    end

    it_behaves_like 'failure response' do
      let(:execute_query) { subject.query(prometheus_query) }
    end
  end

  describe '#series' do
    let(:query_url) { prometheus_series_url('series_name', 'other_service') }

    around do |example|
      Timecop.freeze { example.run }
    end

    it 'calls endpoint and returns list of series' do
      req_stub = stub_prometheus_request(query_url, body: prometheus_series('series_name'))
      expected = prometheus_series('series_name').deep_stringify_keys['data']

      expect(subject.series('series_name', 'other_service')).to eq(expected)

      expect(req_stub).to have_been_requested
    end
  end

  describe '#label_values' do
    let(:query_url) { prometheus_label_values_url('__name__') }

    it 'calls endpoint and returns label values' do
      req_stub = stub_prometheus_request(query_url, body: prometheus_label_values)
      expected = prometheus_label_values.deep_stringify_keys['data']

      expect(subject.label_values('__name__')).to eq(expected)

      expect(req_stub).to have_been_requested
    end
  end

  describe '#query_range' do
    let(:prometheus_query) { prometheus_memory_query('env-slug') }
    let(:query_url) { prometheus_query_range_url(prometheus_query) }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'when non utc time is passed' do
      let(:time_stop) { Time.now.in_time_zone("Warsaw") }
      let(:time_start) { time_stop - 8.hours }

      let(:query_url) { prometheus_query_range_url(prometheus_query, start: time_start.utc.to_f, stop: time_stop.utc.to_f) }

      it 'passed dates are properly converted to utc' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('vector'))

        subject.query_range(prometheus_query, start: time_start, stop: time_stop)
        expect(req_stub).to have_been_requested
      end
    end

    context 'when a start time is passed' do
      let(:query_url) { prometheus_query_range_url(prometheus_query, start: 2.hours.ago) }

      it 'passed it in the requested URL' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('vector'))

        subject.query_range(prometheus_query, start: 2.hours.ago)
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns vector results' do
      it 'returns nil' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('vector'))

        expect(subject.query_range(prometheus_query)).to be_nil
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns matrix results' do
      it 'returns data from the API call' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('matrix'))

        expect(subject.query_range(prometheus_query)).to eq([
          {
            "metric" => {},
            "values" => [[1488758662.506, "0.00002996364761904785"], [1488758722.506, "0.00003090239047619091"]]
          }
        ])
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns no data' do
      it 'returns []' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_empty_body('matrix'))

        expect(subject.query_range(prometheus_query)).to be_empty
        expect(req_stub).to have_been_requested
      end
    end

    it_behaves_like 'failure response' do
      let(:execute_query) { subject.query_range(prometheus_query) }
    end
  end
end
