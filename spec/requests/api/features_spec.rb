require 'spec_helper'

describe API::Features do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  describe 'GET /features' do
    let(:expected_features) do
      [
        {
          'name' => 'feature_1',
          'state' => 'on',
          'gates' => [{ 'key' => 'boolean', 'value' => true }]
        },
        {
          'name' => 'feature_2',
          'state' => 'off',
          'gates' => [{ 'key' => 'boolean', 'value' => false }]
        }
      ]
    end

    before do
      Feature.get('feature_1').enable
      Feature.get('feature_2').disable
    end

    it 'returns a 401 for anonymous users' do
      get api('/features')

      expect(response).to have_http_status(401)
    end

    it 'returns a 403 for users' do
      get api('/features', user)

      expect(response).to have_http_status(403)
    end

    it 'returns the feature list for admins' do
      get api('/features', admin)

      expect(response).to have_http_status(200)
      expect(json_response).to match_array(expected_features)
    end
  end

  describe 'POST /feature' do
    let(:feature_name) { 'my_feature' }
    it 'returns a 401 for anonymous users' do
      post api("/features/#{feature_name}")

      expect(response).to have_http_status(401)
    end

    it 'returns a 403 for users' do
      post api("/features/#{feature_name}", user)

      expect(response).to have_http_status(403)
    end

    it 'creates an enabled feature if passed true' do
      post api("/features/#{feature_name}", admin), value: 'true'

      expect(response).to have_http_status(201)
      expect(Feature.get(feature_name)).to be_enabled
    end

    it 'creates a feature with the given percentage if passed an integer' do
      post api("/features/#{feature_name}", admin), value: '50'

      expect(response).to have_http_status(201)
      expect(Feature.get(feature_name).percentage_of_time_value).to be(50)
    end

    context 'when the feature exists' do
      let(:feature) { Feature.get(feature_name) }

      before do
        feature.disable # This also persists the feature on the DB
      end

      it 'enables the feature if passed true' do
        post api("/features/#{feature_name}", admin), value: 'true'

        expect(response).to have_http_status(201)
        expect(feature).to be_enabled
      end

      context 'with a pre-existing percentage value' do
        before do
          feature.enable_percentage_of_time(50)
        end

        it 'updates the percentage of time if passed an integer' do
          post api("/features/#{feature_name}", admin), value: '30'

          expect(response).to have_http_status(201)
          expect(Feature.get(feature_name).percentage_of_time_value).to be(30)
        end
      end
    end
  end
end
