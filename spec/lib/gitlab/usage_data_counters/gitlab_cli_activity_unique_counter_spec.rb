# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter, :clean_gitlab_redis_shared_state do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::GITLAB_CLI_API_REQUEST_ACTION }

  context 'when tracking a gitlab cli request' do
    context 'with the old UserAgent' do
      let(:user_agent) { { user_agent: 'GLab - GitLab CLI' } }

      it_behaves_like 'a request from an extension'
    end

    context 'with the current UserAgent' do
      let(:user_agent) { { user_agent: 'glab/v1.25.3-27-g7ec258fb (built 2023-02-16), darwin' } }

      it_behaves_like 'a request from an extension'
    end
  end
end
