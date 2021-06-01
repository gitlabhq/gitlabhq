# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Wrapper do
  describe '.instrumentation_class' do
    it 'raises a NameError' do
      expect { described_class.instrumentation_class }.to raise_error(NameError)
    end
  end

  describe '.default_url' do
    it 'is not implemented' do
      expect { described_class.default_url }.to raise_error(NotImplementedError)
    end
  end
end
