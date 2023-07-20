# frozen_string_literal: true

RSpec.shared_examples 'workspaces query in licensed environment and with feature flag on' do
  describe 'when licensed and remote_development_feature_flag feature flag is enabled' do
    before do
      stub_licensed_features(remote_development: true)

      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to match_array(a_hash_including('name' => workspace.name)) }

    context 'when user is not authorized' do
      let(:current_user) { create(:user) }

      it { is_expected.to eq([]) }
    end
  end
end

RSpec.shared_examples 'workspaces query in unlicensed environment and with feature flag off' do
  describe 'when remote_development feature is unlicensed' do
    before do
      stub_licensed_features(remote_development: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns an error' do
      expect(subject).to be_nil
      expect_graphql_errors_to_include(/'remote_development' licensed feature is not available/)
    end
  end

  describe 'when remote_development_feature_flag feature flag is disabled' do
    before do
      stub_licensed_features(remote_development: true)
      stub_feature_flags(remote_development_feature_flag: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns an error' do
      expect(subject).to be_nil
      expect_graphql_errors_to_include(/'remote_development_feature_flag' feature flag is disabled/)
    end
  end
end
