# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::Uri do
  describe '#parse' do
    it 'raises an error if the URI is too long' do
      expect { URI.parse("https://example.com/#{'a' * 25_000}") }.to raise_error(URI::InvalidURIError)
    end

    it 'does not raise an error if the URI is not too long' do
      expect { URI.parse("https://example.com/#{'a' * 14_000}") }.not_to raise_error
    end
  end
end
