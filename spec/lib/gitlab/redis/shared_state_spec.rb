# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::SharedState do
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_SHARED_STATE_CONFIG_FILE" }

  include_examples "redis_shared_examples"

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6382' )
    end
  end
end
