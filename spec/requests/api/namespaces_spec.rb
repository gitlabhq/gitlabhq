require 'spec_helper'

describe API::Namespaces do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group, :nested) }

  describe "GET /namespaces" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/namespaces")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated as admin" do
      it "admin: returns an array of all namespaces" do
        get api("/namespaces", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(Namespace.count)
      end

      it "admin: returns an array of matched namespaces" do
        get api("/namespaces?search=#{group2.name}", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.last['path']).to eq(group2.path)
        expect(json_response.last['full_path']).to eq(group2.full_path)
      end
    end

    context "when authenticated as a regular user" do
      it "user: returns an array of namespaces" do
        get api("/namespaces", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      it "admin: returns an array of matched namespaces" do
        get api("/namespaces?search=#{user.username}", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end
    end
  end

  describe 'PUT /namespaces/:id' do
    context 'when authenticated as admin' do
      it 'updates plan using full_path' do
        put api("/namespaces/#{group1.full_path}", admin), plan: 'silver'

        expect(response).to have_http_status(200)
        expect(json_response['plan']).to eq('silver')
      end

      it 'updates plan using id' do
        put api("/namespaces/#{group1.id}", admin), plan: 'silver'

        expect(response).to have_http_status(200)
        expect(json_response['plan']).to eq('silver')
      end
    end

    context 'when not authenticated as admin' do
      it 'retuns 403' do
        put api("/namespaces/#{group1.id}", user), plan: 'silver'

        expect(response).to have_http_status(403)
      end
    end

    context 'when namespace not found' do
      it 'returns 404' do
        put api("/namespaces/12345", admin), plan: 'silver'

        expect(response).to have_http_status(404)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end

    context 'when invalid params' do
      it 'returns validation error' do
        put api("/namespaces/#{group1.id}", admin), plan: 'unknown'

        expect(response).to have_http_status(400)
        expect(json_response['message']).to eq('plan' => ['is not included in the list'])
      end
    end
  end
end
