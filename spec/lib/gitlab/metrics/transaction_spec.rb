# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Transaction do
  describe '#run' do
    specify { expect { described_class.new.run }.to raise_error(NotImplementedError) }
  end
end
