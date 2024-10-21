# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter, :clean_gitlab_redis_shared_state, feature_category: :editor_extensions do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::JETBRAINS_BUNDLED_API_REQUEST_ACTION }
  let(:user_agent_string) do
    'IntelliJ-GitLab-Plugin PhpStorm/PS-232.6734.11 (JRE 17.0.7+7-b966.2; Linux 6.2.0-20-generic; amd64)'
  end

  let(:user_agent) { { user_agent: user_agent_string } }

  context 'when tracking a jetbrains bundled api request' do
    it_behaves_like 'a request from an extension'
  end
end
