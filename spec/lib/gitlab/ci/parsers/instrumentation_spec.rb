# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Instrumentation do
  describe '#parse!' do
    let(:parser_class) do
      Class.new do
        prepend Gitlab::Ci::Parsers::Instrumentation

        def parse!(arg1, arg2:)
          "parse #{arg1} #{arg2}"
        end
      end
    end

    it 'sets metrics for duration of parsing' do
      result = parser_class.new.parse!('hello', arg2: 'world')

      expect(result).to eq('parse hello world')

      metrics = Gitlab::Metrics.registry.get(:ci_report_parser_duration_seconds).get({ parser: parser_class.name })

      expect(metrics.keys).to match_array(described_class::BUCKETS)
    end
  end
end
