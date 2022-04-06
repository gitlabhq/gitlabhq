# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ImportExport::DurationMeasuring do
  subject do
    Class.new do
      include Gitlab::ImportExport::DurationMeasuring

      def test
        with_duration_measuring do
          'test'
        end
      end
    end.new
  end

  it 'measures method execution duration' do
    subject.test

    expect(subject.duration_s).not_to be_nil
  end

  describe '#with_duration_measuring' do
    it 'yields control' do
      expect { |block| subject.with_duration_measuring(&block) }.to yield_control
    end

    it 'returns result of the yielded block' do
      return_value = 'return_value'

      expect(subject.with_duration_measuring { return_value }).to eq(return_value)
    end
  end
end
