require 'spec_helper'

describe API::Version do
  shared_examples_for 'GET /version' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/version')

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }

      it 'returns the version information' do
        get api('/version', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['version']).to eq(Gitlab::VERSION)
        expect(json_response['revision']).to eq(Gitlab.revision)
      end
    end
  end

  context 'with graphql enabled' do
    before do
      stub_feature_flags(graphql: true)
    end

    include_examples 'GET /version'
  end

  context 'with graphql disabled' do
    before do
      stub_feature_flags(graphql: false)
    end

    include_examples 'GET /version'
  end
end
