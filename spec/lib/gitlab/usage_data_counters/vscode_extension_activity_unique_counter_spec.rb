# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter, :clean_gitlab_redis_shared_state do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::VS_CODE_API_REQUEST_ACTION }
  let(:user_agent) { { user_agent: 'vs-code-gitlab-workflow/3.11.1 VSCode/1.52.1 Node.js/12.14.1 (darwin; x64)' } }

  context 'when tracking a vs code api request' do
    it_behaves_like 'a request from an extension'
  end
end
