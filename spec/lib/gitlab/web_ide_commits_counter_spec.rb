# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::WebIdeCommitsCounter, :clean_gitlab_redis_shared_state do
  describe '.increment' do
    it 'increments the web ide commits counter by 1' do
      expect do
        described_class.increment
      end.to change { described_class.total_count }.from(0).to(1)
    end
  end

  describe '.total_count' do
    it 'returns the total amount of web ide commits' do
      expect(described_class.total_count).to eq(0)
    end
  end
end
