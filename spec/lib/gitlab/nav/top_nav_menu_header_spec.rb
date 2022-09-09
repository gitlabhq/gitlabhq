# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::Gitlab::Nav::TopNavMenuHeader do
  describe '.build' do
    it 'builds a hash from with the given header' do
      title = 'Test Header'
      expected = {
        title: title,
        type: :header
      }
      expect(described_class.build(title: title)).to eq(expected)
    end
  end
end
