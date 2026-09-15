# frozen_string_literal: true

RSpec.shared_examples 'a merge request saved views mutation gated by the mr_dashboard_saved_views feature flag' do
  context 'when the mr_dashboard_saved_views feature flag is disabled' do
    before do
      stub_feature_flags(mr_dashboard_saved_views: false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
