# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter, :clean_gitlab_redis_shared_state do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::JETBRAINS_API_REQUEST_ACTION }
  let(:user_agent) { { user_agent: 'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4 java/11.0.13 mac-os-x/aarch64/12.1' } }

  context 'when tracking a jetbrains api request' do
    it_behaves_like 'a request from an extension'
  end
end
