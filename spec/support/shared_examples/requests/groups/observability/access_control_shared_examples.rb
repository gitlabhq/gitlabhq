# frozen_string_literal: true

RSpec.shared_examples 'observability requires feature flag' do
  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(observability_sass_features: false)
    end

    it 'returns 404' do
      subject
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'observability requires permissions' do
  context 'without proper permissions' do
    before do
      group.members.find_by(user: user).destroy!
    end

    it 'returns 404' do
      subject
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
