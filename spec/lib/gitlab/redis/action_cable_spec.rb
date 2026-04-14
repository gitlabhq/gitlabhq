# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ActionCable, feature_category: :redis do
  include TmpdirHelper

  context 'as a redis wrapper' do
    let(:instance_specific_config_file) { "config/redis.action_cable.yml" }

    include_examples "redis_shared_examples"
  end

  describe '#config_fallback' do
    it 'returns SharedState' do
      expect(described_class.config_fallback).to eq(Gitlab::Redis::SharedState)
    end
  end

  describe '#active?' do
    let(:rails_root) { mktmpdir }

    before do
      FileUtils.mkdir_p(File.join(rails_root, 'config'))
      allow(described_class).to receive(:rails_root).and_return(rails_root)
    end

    after do
      FileUtils.rm_rf(rails_root)
    end

    context 'when redis.action_cable.yml exists' do
      before do
        File.write(File.join(rails_root, 'config/redis.action_cable.yml'), 'test: {}')
      end

      it 'returns true' do
        expect(described_class.active?).to be true
      end
    end

    context 'when redis.action_cable.yml does not exist' do
      it 'returns false' do
        expect(described_class.active?).to be false
      end
    end
  end
end
