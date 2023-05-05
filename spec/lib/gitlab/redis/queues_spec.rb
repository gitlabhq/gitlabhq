# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Queues do
  let(:instance_specific_config_file) { "config/redis.queues.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_QUEUES_CONFIG_FILE" }

  include_examples "redis_shared_examples"

  describe '#raw_config_hash' do
    before do
      expect(subject).to receive(:fetch_config) { config }
    end

    context 'when the config url is present' do
      let(:config) { { url: 'redis://localhost:1111' } }

      it 'sets the configured url' do
        expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:1111' )
      end
    end
  end
end
