# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter, :clean_gitlab_redis_shared_state do # rubocop:disable RSpec/FilePath
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::GITLAB_CLI_API_REQUEST_ACTION }
  let(:user_agent) { { user_agent: 'GLab - GitLab CLI' } }

  context 'when tracking a gitlab cli request' do
    it_behaves_like 'a request from an extension'
  end
end
