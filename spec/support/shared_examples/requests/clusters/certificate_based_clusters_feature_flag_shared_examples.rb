# frozen_string_literal: true

RSpec.shared_examples ':certificate_based_clusters feature flag API responses' do
  context 'feature flag is disabled' do
    before do
      stub_feature_flags(certificate_based_clusters: false)
    end

    it 'responds with :not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
