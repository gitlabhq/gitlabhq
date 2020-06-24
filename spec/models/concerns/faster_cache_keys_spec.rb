# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FasterCacheKeys do
  describe '#cache_key' do
    it 'returns a String' do
      # We're using a fixed string here so it's easier to set an expectation for
      # the resulting cache key.
      time = '2016-08-08 16:39:00+02'
      issue = build(:issue, updated_at: time)
      issue.extend(described_class)

      expect(issue).to receive(:id).and_return(1)

      expect(issue.cache_key).to eq("issues/1-#{time}")
    end
  end
end
