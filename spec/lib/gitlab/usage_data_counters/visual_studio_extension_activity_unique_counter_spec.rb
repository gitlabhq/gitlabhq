# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::VisualStudioExtensionActivityUniqueCounter, :clean_gitlab_redis_shared_state, feature_category: :editor_extensions do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }
  let(:action) { described_class::VISUAL_STUDIO_EXTENSION_API_REQUEST_ACTION }
  let(:user_agent_string) do
    'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
  end

  let(:user_agent) { { user_agent: user_agent_string } }

  context 'when tracking a visual studio api request' do
    it_behaves_like 'a request from an extension'
  end
end
