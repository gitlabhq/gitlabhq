# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

describe Gitlab::InstrumentationHelper do
  using RSpec::Parameterized::TableSyntax

  describe '.add_instrumentation_data', :request_store do
    let(:payload) { {} }

    subject { described_class.add_instrumentation_data(payload) }

    it 'adds nothing' do
      subject

      expect(payload).to eq({})
    end

    context 'when Gitaly calls are made' do
      it 'adds Gitaly data and omits Redis data' do
        project = create(:project)
        RequestStore.clear!
        project.repository.exists?

        subject

        expect(payload[:gitaly_calls]).to eq(1)
        expect(payload[:gitaly_duration_s]).to be >= 0
        expect(payload[:redis_calls]).to be_nil
        expect(payload[:redis_duration_ms]).to be_nil
      end
    end

    context 'when Redis calls are made' do
      it 'adds Redis data and omits Gitaly data' do
        Gitlab::Redis::Cache.with { |redis| redis.get('test-instrumentation') }

        subject

        expect(payload[:redis_calls]).to eq(1)
        expect(payload[:redis_duration_s]).to be >= 0
        expect(payload[:gitaly_calls]).to be_nil
        expect(payload[:gitaly_duration]).to be_nil
      end
    end
  end

  describe '.queue_duration_for_job' do
    where(:enqueued_at, :created_at, :time_now, :expected_duration) do
      "2019-06-01T00:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.000+0000" | 2.hours.to_f
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.001+0000" | 0.001
      "2019-06-01T02:00:00.000+0000" | "2019-05-01T02:00:00.000+0000" | "2019-06-01T02:00:01.000+0000" | 1
      nil                            | "2019-06-01T02:00:00.000+0000" | "2019-06-01T02:00:00.001+0000" | 0.001
      nil                            | nil                            | "2019-06-01T02:00:00.001+0000" | nil
      "2019-06-01T02:00:00.000+0200" | nil                            | "2019-06-01T02:00:00.000-0200" | 4.hours.to_f
      1571825569.998168              | nil                            | "2019-10-23T12:13:16.000+0200" | 26.001832
      1571825569                     | nil                            | "2019-10-23T12:13:16.000+0200" | 27
      "invalid_date"                 | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      ""                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      0                              | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      -1                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T00:00:00.000+0000" | 0
      Time.at(1571999233)            | nil                            | "2019-10-25T12:29:16.000+0200" | 123
    end

    with_them do
      let(:job) { { 'enqueued_at' => enqueued_at, 'created_at' => created_at } }

      it "returns the correct duration" do
        Timecop.freeze(Time.iso8601(time_now)) do
          expect(described_class.queue_duration_for_job(job)).to eq(expected_duration)
        end
      end
    end
  end
end
