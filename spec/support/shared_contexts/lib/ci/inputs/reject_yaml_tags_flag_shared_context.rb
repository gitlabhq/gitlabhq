# frozen_string_literal: true

# Keeps these specs on `fast_spec_helper`, which has no Rails and so cannot read a real
# flag. Only this flag is stubbed; any other config flag read here will still fail.
# Remove this file and its includes with the flag:
# https://gitlab.com/gitlab-org/gitlab/-/issues/607488
RSpec.shared_context 'with ci_reject_yaml_tags_in_inputs enabled' do
  before do
    allow(::Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?).and_call_original
    allow(::Gitlab::Ci::Config::FeatureFlags)
      .to receive(:enabled?).with(:ci_reject_yaml_tags_in_inputs).and_return(true)
  end
end
