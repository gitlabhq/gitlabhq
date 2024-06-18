# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::WebIdeCounter, :clean_gitlab_redis_shared_state do
  shared_examples 'counter examples' do |event|
    it 'increments counter and return the total count' do
      expect(described_class.public_send(:total_count, event)).to eq(0)

      2.times { described_class.public_send(:"increment_#{event}_count") }

      redis_key = "web_ide_#{event}_count".upcase
      expect(described_class.public_send(:total_count, redis_key)).to eq(2)
    end
  end

  describe 'terminals counter' do
    it_behaves_like 'counter examples', 'terminals'
  end

  describe 'pipelines counter' do
    it_behaves_like 'counter examples', 'pipelines'
  end

  describe '.totals' do
    terminals = 1
    pipelines = 2

    before do
      terminals.times { described_class.increment_terminals_count }
      pipelines.times { described_class.increment_pipelines_count }
    end

    it 'can report all totals' do
      expect(described_class.totals).to include(
        web_ide_terminals: terminals
      )
    end
  end
end
