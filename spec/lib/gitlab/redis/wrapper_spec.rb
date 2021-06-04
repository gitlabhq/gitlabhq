# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Wrapper do
  describe '.instrumentation_class' do
    it 'raises a NameError' do
      expect { described_class.instrumentation_class }.to raise_error(NameError)
    end
  end
end
