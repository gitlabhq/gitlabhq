# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqProcess, feature_category: :scalability do
  let(:cap) { Sidekiq::Capsule.new('test', Sidekiq.default_configuration) }

  before do
    Thread.current[:sidekiq_capsule] = cap
  end

  after do
    Thread.current[:sidekiq_capsule] = nil
  end

  describe '#tid' do
    it 'matches sidekiq internals' do
      expect(described_class.tid).to eq(cap.tid)
    end
  end

  describe '#pid' do
    it 'matches sidekiq internals' do
      expect(described_class.pid).to eq(cap.identity)
    end
  end
end
