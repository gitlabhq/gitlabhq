# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rapid_diffs/server_timings'

RSpec.describe Gitlab::RapidDiffs::ServerTimings, feature_category: :source_code_management do
  subject(:server_timings) { described_class.new }

  describe '#measure' do
    it 'returns the block result' do
      result = server_timings.measure(:test) { 42 }

      expect(result).to eq(42)
    end

    it 'accumulates durations for the same metric' do
      server_timings.measure(:rpc) { nil }
      server_timings.measure(:rpc) { nil }

      attributes = server_timings.to_html_attributes
      duration = attributes.match(/rpc="([\d.]+)"/)[1].to_f

      expect(duration).to be >= 0.0
    end

    it 'tracks multiple distinct metrics' do
      server_timings.measure(:rpc) { nil }
      server_timings.measure(:rendering) { nil }

      attributes = server_timings.to_html_attributes

      expect(attributes).to include('rpc=')
      expect(attributes).to include('rendering=')
    end
  end

  describe '#to_html_attributes' do
    it 'returns empty string when no metrics are recorded' do
      expect(server_timings.to_html_attributes).to eq('')
    end

    it 'formats metrics as HTML attributes' do
      server_timings.measure(:streaming) { nil }

      expect(server_timings.to_html_attributes).to match(/\Astreaming="\d+\.\d+"\z/)
    end

    it 'includes all recorded metrics' do
      server_timings.measure(:rpc) { nil }
      server_timings.measure(:highlighting) { nil }
      server_timings.measure(:rendering) { nil }

      attributes = server_timings.to_html_attributes

      expect(attributes).to include('rpc=')
      expect(attributes).to include('highlighting=')
      expect(attributes).to include('rendering=')
    end
  end

  describe '#to_server_timing_header' do
    it 'returns empty string when no metrics are recorded' do
      expect(server_timings.to_server_timing_header).to eq('')
    end

    it 'formats metrics as Server-Timing header value with millisecond durations' do
      server_timings.measure(:rpc) { sleep(0.01) }

      header = server_timings.to_server_timing_header

      expect(header).to match(/\Arpc;dur=\d+\.\d+\z/)
      dur = header.match(/dur=([\d.]+)/)[1].to_f
      expect(dur).to be >= 10.0
    end

    it 'separates multiple metrics with commas' do
      server_timings.measure(:rpc) { nil }
      server_timings.measure(:rendering) { nil }

      header = server_timings.to_server_timing_header

      expect(header).to match(/rpc;dur=[\d.]+, rendering;dur=[\d.]+/)
    end
  end
end
