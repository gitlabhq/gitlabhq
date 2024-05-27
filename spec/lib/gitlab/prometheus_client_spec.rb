# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PrometheusClient do
  include PrometheusHelpers

  subject { described_class.new('https://prometheus.example.com') }

  describe '#ping' do
    it 'issues a "query" request to the API endpoint' do
      req_stub = stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector'))

      expect(subject.ping).to eq({ "resultType" => "vector", "result" => [{ "metric" => {}, "value" => [1488772511.004, "0.000041021495238095323"] }] })
      expect(req_stub).to have_been_requested
    end
  end

  describe '#healthy?' do
    it 'returns true when status code is 200 and healthy response body' do
      stub_request(:get, subject.health_url).to_return(status: 200, body: described_class::HEALTHY_RESPONSE)

      expect(subject.healthy?).to eq(true)
    end

    it 'returns false when status code is 200 and unhealthy response body' do
      stub_request(:get, subject.health_url).to_return(status: 200, body: '')

      expect(subject.healthy?).to eq(false)
    end

    it 'raises error when status code not 200' do
      stub_request(:get, subject.health_url).to_return(status: 500, body: '')

      expect { subject.healthy? }.to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError)
    end
  end

  describe '#ready?' do
    it 'returns true when status code is 200' do
      stub_request(:get, subject.ready_url).to_return(status: 200, body: 'Prometheus is Ready.\n')

      expect(subject.ready?).to eq(true)
    end

    it 'returns false when status code is not 200' do
      [503, 500].each do |code|
        stub_request(:get, subject.ready_url).to_return(status: code, body: 'Service Unavailable')

        expect(subject.ready?).to eq(false)
      end
    end

    it 'raises error when ready api throws exception' do
      stub_request(:get, subject.ready_url).to_raise(Net::OpenTimeout)

      expect { subject.ready? }.to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError)
    end
  end

  # This shared examples expect:
  # - query_url: A query URL
  # - execute_query: A query call
  shared_examples 'failure response' do
    context 'when request returns 400 with an error message' do
      it 'raises a Gitlab::PrometheusClient::QueryError error' do
        req_stub = stub_prometheus_request(query_url, status: 400, body: { error: 'bar!' })

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::QueryError, 'bar!')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns 400 without an error message' do
      it 'raises a Gitlab::PrometheusClient::QueryError error' do
        req_stub = stub_prometheus_request(query_url, status: 400)

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::QueryError, 'Bad data received')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns 500' do
      it 'raises a Gitlab::PrometheusClient::UnexpectedResponseError error' do
        req_stub = stub_prometheus_request(query_url, status: 500, body: { message: 'FAIL!' })

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError, '500 - {"message":"FAIL!"}')
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns non json data' do
      it 'raises a Gitlab::PrometheusClient::UnexpectedResponseError error' do
        req_stub = stub_prometheus_request(query_url, status: 200, body: 'not json')

        expect { execute_query }
          .to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError, 'Parsing response failed')
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe 'failure to reach a provided prometheus url' do
    let(:prometheus_url) { "https://prometheus.invalid.example.com/api/v1/query?query=1" }

    shared_examples 'exceptions are raised' do
      Gitlab::HTTP::HTTP_ERRORS.each do |error|
        it "raises a Gitlab::PrometheusClient::ConnectionError when a #{error} is rescued" do
          req_stub = stub_prometheus_request_with_exception(prometheus_url, error.new)

          expect { subject }
            .to raise_error(Gitlab::PrometheusClient::ConnectionError, kind_of(String))
          expect(req_stub).to have_been_requested
        end
      end
    end

    context 'ping' do
      subject { described_class.new(prometheus_url).ping }

      it_behaves_like 'exceptions are raised'
    end

    context 'proxy' do
      subject { described_class.new(prometheus_url).proxy('query', { query: '1' }) }

      it_behaves_like 'exceptions are raised'
    end
  end

  describe '#query' do
    let(:prometheus_query) { prometheus_cpu_query('env-slug') }
    let(:query_url) { prometheus_query_with_time_url(prometheus_query, Time.now.utc) }

    around do |example|
      freeze_time { example.run }
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

  describe '#aggregate' do
    let(:query) { 'avg (metric) by (job)' }
    let(:prometheus_response) do
      {
        status: "success",
        data: {
          resultType: "vector",
          result: [
            {
              metric: { "job" => "gitlab-rails" },
              value: [1488758662.506, "1"]
            },
            {
              metric: { "job" => "gitlab-sidekiq" },
              value: [1488758662.506, "2"]
            }
          ]
        }
      }
    end

    let(:query_url) { prometheus_query_with_time_url(query, Time.now.utc) }

    around do |example|
      freeze_time { example.run }
    end

    context 'when request returns vector results' do
      it 'returns data from the API call grouped by labels' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_response)

        expect(subject.aggregate(query)).to eq({
          { "job" => "gitlab-rails" } => 1,
          { "job" => "gitlab-sidekiq" } => 2
        })
        expect(req_stub).to have_been_requested
      end
    end

    context 'when request returns no data' do
      it 'returns {}' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_empty_body('vector'))

        expect(subject.aggregate(query)).to eq({})
        expect(req_stub).to have_been_requested
      end
    end

    it_behaves_like 'failure response' do
      let(:execute_query) { subject.aggregate(query) }
    end
  end

  describe '#series' do
    let(:query_url) { prometheus_series_url('series_name', 'other_service') }

    around do |example|
      freeze_time { example.run }
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
      freeze_time { example.run }
    end

    context 'when non utc time is passed' do
      let(:time_stop) { Time.now.in_time_zone("Warsaw") }
      let(:time_start) { time_stop - 8.hours }

      let(:query_url) { prometheus_query_range_url(prometheus_query, start_time: time_start.utc.to_f, end_time: time_stop.utc.to_f) }

      it 'passed dates are properly converted to utc' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('vector'))

        subject.query_range(prometheus_query, start_time: time_start, end_time: time_stop)
        expect(req_stub).to have_been_requested
      end
    end

    context 'when a start time is passed' do
      let(:query_url) { prometheus_query_range_url(prometheus_query, start_time: 2.hours.ago) }

      it 'passed it in the requested URL' do
        req_stub = stub_prometheus_request(query_url, body: prometheus_values_body('vector'))

        subject.query_range(prometheus_query, start_time: 2.hours.ago)
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

        expect(subject.query_range(prometheus_query)).to eq(
          [
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

  describe '.compute_step' do
    using RSpec::Parameterized::TableSyntax

    let(:now) { Time.now.utc }

    subject { described_class.compute_step(start, stop) }

    where(:time_interval_in_seconds, :step) do
      0               | 60
      10.hours        | 60
      (10.hours + 1) | 61
      # frontend options
      30.minutes      | 60
      3.hours         | 60
      8.hours         | 60
      1.day           | 144
      3.days          | 432
      1.week          | 1008
    end

    with_them do
      let(:start) { now - time_interval_in_seconds }
      let(:stop) { now }

      it { is_expected.to eq(step) }
    end
  end

  describe 'proxy' do
    context 'get API' do
      let(:prometheus_query) { prometheus_cpu_query('env-slug') }
      let(:query_url) { prometheus_query_url(prometheus_query) }

      around do |example|
        freeze_time { example.run }
      end

      context 'when response status code is 200' do
        it 'returns response object' do
          req_stub = stub_prometheus_request(query_url, body: prometheus_value_body('vector'))

          response = subject.proxy('query', { query: prometheus_query })
          json_response = Gitlab::Json.parse(response.body)

          expect(response.code).to eq(200)
          expect(json_response).to eq({
            'status' => 'success',
            'data' => {
              'resultType' => 'vector',
              'result' => [{ "metric" => {}, "value" => [1488772511.004, "0.000041021495238095323"] }]
            }
          })
          expect(req_stub).to have_been_requested
        end
      end

      context 'when response status code is not 200' do
        it 'returns response object' do
          req_stub = stub_prometheus_request(query_url, status: 400, body: { error: 'error' })

          response = subject.proxy('query', { query: prometheus_query })
          json_response = Gitlab::Json.parse(response.body)

          expect(req_stub).to have_been_requested
          expect(response.code).to eq(400)
          expect(json_response).to eq('error' => 'error')
        end
      end

      context 'when Gitlab::HTTP::ResponseError is raised' do
        before do
          stub_prometheus_request_with_exception(query_url, response_error)
        end

        context "without response code" do
          let(:response_error) { Gitlab::HTTP::ResponseError }

          it 'raises PrometheusClient::ConnectionError' do
            expect { subject.proxy('query', { query: prometheus_query }) }.to(
              raise_error(Gitlab::PrometheusClient::ConnectionError, 'Network connection error')
            )
          end
        end

        context "with response code" do
          let(:response_error) do
            response = Net::HTTPResponse.new(1.1, 400, '{}sumpthin')
            allow(response).to receive(:body) { '{}' }
            Gitlab::HTTP::ResponseError.new(response)
          end

          it 'raises Gitlab::PrometheusClient::QueryError' do
            expect { subject.proxy('query', { query: prometheus_query }) }.to(
              raise_error(Gitlab::PrometheusClient::QueryError, 'Bad data received')
            )
          end
        end
      end
    end
  end
end
