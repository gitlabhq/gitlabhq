# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ActionCable, feature_category: :redis do
  include TmpdirHelper

  context 'as a redis wrapper' do
    let(:instance_specific_config_file) { "config/redis.action_cable.yml" }

    include_examples "redis_shared_examples"
  end

  describe '#config_fallback' do
    it 'returns nil' do
      expect(described_class.config_fallback).to be_nil
    end
  end

  describe '#fetch_config' do
    let(:rails_root) { mktmpdir }

    subject(:config) { described_class.new('test').send(:fetch_config) }

    before do
      FileUtils.mkdir_p(File.join(rails_root, 'config'))

      allow(described_class).to receive(:rails_root).and_return(rails_root)
    end

    context 'when no redis config file exsits' do
      it 'returns nil' do
        expect(config).to be_nil
      end

      context 'when resque.yml exists' do
        before do
          File.write(File.join(rails_root, 'config/resque.yml'), {
            'test' => { 'foobar' => 123 }
          }.to_json)
        end

        it 'returns the config from resque.yml' do
          expect(config).to eq({ 'foobar' => 123 })
        end
      end
    end
  end
end
