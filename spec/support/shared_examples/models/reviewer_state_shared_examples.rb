# frozen_string_literal: true

RSpec.shared_examples 'having reviewer state' do
  describe 'mr_attention_requests feature flag is disabled' do
    before do
      stub_feature_flags(mr_attention_requests: false)
    end

    it { is_expected.to have_attributes(state: 'unreviewed') }
  end

  describe 'mr_attention_requests feature flag is enabled' do
    it { is_expected.to have_attributes(state: 'attention_requested') }
  end
end
