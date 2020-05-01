# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elasticsearch::Logs::Lines do
  let(:client) { Elasticsearch::Transport::Client }

  let(:es_message_1) { { timestamp: "2019-12-13T14:35:34.034Z", pod: "production-6866bc8974-m4sk4", message: "10.8.2.1 - - [25/Oct/2019:08:03:22 UTC] \"GET / HTTP/1.1\" 200 13" } }
  let(:es_message_2) { { timestamp: "2019-12-13T14:35:35.034Z", pod: "production-6866bc8974-m4sk4", message: "10.8.2.1 - - [27/Oct/2019:23:49:54 UTC] \"GET / HTTP/1.1\" 200 13" } }
  let(:es_message_3) { { timestamp: "2019-12-13T14:35:36.034Z", pod: "production-6866bc8974-m4sk4", message: "10.8.2.1 - - [04/Nov/2019:23:09:24 UTC] \"GET / HTTP/1.1\" 200 13" } }
  let(:es_message_4) { { timestamp: "2019-12-13T14:35:37.034Z", pod: "production-6866bc8974-m4sk4", message: "- -\u003e /" } }

  let(:es_response) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/logs_response.json')) }

  subject { described_class.new(client) }

  let(:namespace) { "autodevops-deploy-9-production" }
  let(:pod_name) { "production-6866bc8974-m4sk4" }
  let(:container_name) { "auto-deploy-app" }
  let(:search) { "foo +bar "}
  let(:start_time) { "2019-12-13T14:35:34.034Z" }
  let(:end_time) { "2019-12-13T14:35:34.034Z" }
  let(:cursor) { "9999934,1572449784442" }

  let(:body) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query.json')) }
  let(:body_with_container) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_container.json')) }
  let(:body_with_search) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_search.json')) }
  let(:body_with_times) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_times.json')) }
  let(:body_with_start_time) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_start_time.json')) }
  let(:body_with_end_time) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_end_time.json')) }
  let(:body_with_cursor) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_cursor.json')) }
  let(:body_with_filebeat_6) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/query_with_filebeat_6.json')) }

  RSpec::Matchers.define :a_hash_equal_to_json do |expected|
    match do |actual|
      actual.as_json == expected
    end
  end

  describe '#pod_logs' do
    it 'returns the logs as an array' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can further filter the logs by container name' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_container)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, container_name: container_name)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can further filter the logs by search' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_search)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, search: search)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can further filter the logs by start_time and end_time' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_times)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, start_time: start_time, end_time: end_time)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can further filter the logs by only start_time' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_start_time)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, start_time: start_time)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can further filter the logs by only end_time' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_end_time)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, end_time: end_time)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can search after a cursor' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_cursor)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, cursor: cursor)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end

    it 'can search on filebeat 6' do
      expect(client).to receive(:search).with(body: a_hash_equal_to_json(body_with_filebeat_6)).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name: pod_name, filebeat7: false)
      expect(result).to eq(logs: [es_message_4, es_message_3, es_message_2, es_message_1], cursor: cursor)
    end
  end
end
