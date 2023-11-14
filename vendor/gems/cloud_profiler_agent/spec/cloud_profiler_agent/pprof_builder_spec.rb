# frozen_string_literal: true

require 'cloud_profiler_agent'

RSpec.describe CloudProfilerAgent::PprofBuilder, feature_category: :cloud_connector do
  subject { described_class.new(profile, start_time, end_time) }

  # load_profile loads one of the example profiles created by
  # script/generate_profile.rb
  def load_profile(name)
    # We are disabling this security check since we are loading static files that we generated ourselves, and it is
    # only used in specs. This is the same method StackProf uses:
    # https://github.com/tmm1/stackprof/blob/master/lib/stackprof/report.rb#L14
    Marshal.load(File.binread(File.expand_path("#{name}.stackprof", __dir__))) # rubocop:disable Security/MarshalLoad
  end

  def get_str(index)
    message.string_table.fetch(index)
  end

  let(:start_time) { Time.new(2020, 10, 31, 17, 12, 0) }
  let(:end_time) { Time.new(2020, 10, 31, 17, 12, 30) }

  # message is the protobuf object, which typically gets serialized and gzip'd
  # before being sent to the Profiler API or written to disk. Rather than
  # unzipping and deserializing all the time, we will be making a lot of
  # assertions about the message directly.
  let(:message) { subject.message }

  context 'with :cpu profile' do
    let(:profile) { load_profile(:cpu) }

    it 'has a sample type of [["cpu", "nanoseconds"]]' do
      expect(message.sample_type.length).to eq(1)

      sample_type = message.sample_type.first
      expect(get_str(sample_type.type)).to eq('cpu')
      expect(get_str(sample_type.unit)).to eq('nanoseconds')
    end

    it 'has a period of 100,000 cpu nanoseconds' do
      expect(message.period).to eq(100_000)
      period_type = message.period_type
      expect(get_str(period_type.type)).to eq('cpu')
      expect(get_str(period_type.unit)).to eq('nanoseconds')
    end

    it 'has a duration of 30 seconds' do
      expect(message.duration_nanos).to eq(30 * 1_000_000_000)
    end

    it 'has the start time' do
      expect(message.time_nanos).to eq(start_time.to_i * 1_000_000_000)
    end
  end

  context 'with :wall profile' do
    let(:profile) { load_profile(:wall) }

    it 'has a sample type of [["wall", "nanoseconds"]]' do
      expect(message.sample_type.length).to eq(1)

      sample_type = message.sample_type.first
      expect(get_str(sample_type.type)).to eq('wall')
      expect(get_str(sample_type.unit)).to eq('nanoseconds')
    end

    it 'has a period of 100,000 wall nanoseconds' do
      expect(message.period).to eq(100_000)
      period_type = message.period_type
      expect(get_str(period_type.type)).to eq('wall')
      expect(get_str(period_type.unit)).to eq('nanoseconds')
    end

    it 'has a sum time of about 1 second' do
      sum_nanos = 0
      message.sample.each do |sample|
        sum_nanos += sample.value.first
      end

      expect(sum_nanos).to be_within(1_000_000).of(1_000_000_000)
    end
  end

  context 'with :object profile' do
    let(:profile) { load_profile(:object) }

    it 'has a sample type of [["alloc_objects", "count"]]' do
      expect(message.sample_type.length).to eq(1)

      sample_type = message.sample_type.first
      expect(get_str(sample_type.type)).to eq('alloc_objects')
      expect(get_str(sample_type.unit)).to eq('count')
    end

    it 'has a period of 100 alloc_objects count' do
      expect(message.period).to eq(100)
      period_type = message.period_type
      expect(get_str(period_type.type)).to eq('alloc_objects')
      expect(get_str(period_type.unit)).to eq('count')
    end
  end
end
