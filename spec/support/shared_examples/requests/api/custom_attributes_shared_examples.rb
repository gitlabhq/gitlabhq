# frozen_string_literal: true

RSpec.shared_examples 'custom attributes endpoints' do |attributable_name|
  let!(:custom_attribute1) { attributable.custom_attributes.create! key: 'foo', value: 'foo' }
  let!(:custom_attribute2) { attributable.custom_attributes.create! key: 'bar', value: 'bar' }

  describe "GET /#{attributable_name} with custom attributes filter", :aggregate_failures do
    before do
      other_attributable
    end

    context 'with an unauthorized user' do
      it 'does not filter by custom attributes' do
        get api("/#{attributable_name}", user), params: { custom_attributes: { foo: 'foo', bar: 'bar' } }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to include(attributable.id, other_attributable.id)
      end
    end

    context 'with an authorized user' do
      it 'filters by custom attributes' do
        get api("/#{attributable_name}", admin, admin_mode: true), params: { custom_attributes: { foo: 'foo', bar: 'bar' } }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to be 1
        expect(json_response.first['id']).to eq attributable.id
      end
    end
  end

  describe "GET /#{attributable_name} with custom attributes", :aggregate_failures do
    before do
      other_attributable
    end

    context 'with an unauthorized user' do
      it 'does not include custom attributes' do
        get api("/#{attributable_name}", user), params: { with_custom_attributes: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to be_empty
        expect(json_response.first).not_to include 'custom_attributes'
      end
    end

    context 'with an authorized user' do
      it 'does not include custom attributes by default' do
        get api("/#{attributable_name}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to be_empty
        expect(json_response.first).not_to include 'custom_attributes'
      end

      it 'includes custom attributes if requested' do
        get api("/#{attributable_name}", admin, admin_mode: true), params: { with_custom_attributes: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to be_empty

        attributable_response = json_response.find { |r| r['id'] == attributable.id }
        other_attributable_response = json_response.find { |r| r['id'] == other_attributable.id }

        expect(attributable_response['custom_attributes']).to contain_exactly(
          { 'key' => 'foo', 'value' => 'foo' },
          { 'key' => 'bar', 'value' => 'bar' }
        )

        expect(other_attributable_response['custom_attributes']).to eq []
      end
    end
  end

  describe "GET /#{attributable_name}/:id with custom attributes", :aggregate_failures do
    context 'with an unauthorized user' do
      it 'does not include custom attributes' do
        get api("/#{attributable_name}/#{attributable.id}", user), params: { with_custom_attributes: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include 'custom_attributes'
      end
    end

    context 'with an authorized user' do
      it 'does not include custom attributes by default' do
        get api("/#{attributable_name}/#{attributable.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to include 'custom_attributes'
      end

      it 'includes custom attributes if requested' do
        get api("/#{attributable_name}/#{attributable.id}", admin, admin_mode: true), params: { with_custom_attributes: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['custom_attributes']).to contain_exactly(
          { 'key' => 'foo', 'value' => 'foo' },
          { 'key' => 'bar', 'value' => 'bar' }
        )
      end
    end
  end

  describe "GET /#{attributable_name}/:id/custom_attributes", :aggregate_failures do
    context 'with an unauthorized user' do
      subject { get api("/#{attributable_name}/#{attributable.id}/custom_attributes", user) }

      it_behaves_like 'an unauthorized API user'
    end

    context 'with an authorized user' do
      it 'returns all custom attributes' do
        get api("/#{attributable_name}/#{attributable.id}/custom_attributes", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to contain_exactly(
          { 'key' => 'foo', 'value' => 'foo' },
          { 'key' => 'bar', 'value' => 'bar' }
        )
      end

      it "returns :not_found when #{attributable_name} does not exist" do
        get api("/#{attributable_name}/#{non_existing_record_id}/custom_attributes", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /#{attributable_name}/:id/custom_attributes/:key", :aggregate_failures do
    context 'with an unauthorized user' do
      subject { get api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", user) }

      it_behaves_like 'an unauthorized API user'
    end

    context 'with an authorized user' do
      it 'returns a single custom attribute' do
        get api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'key' => 'foo', 'value' => 'foo' })
      end

      it "returns :not_found when #{attributable_name} does not exist" do
        get api("/#{attributable_name}/#{non_existing_record_id}/custom_attributes/foo", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "PUT /#{attributable_name}/:id/custom_attributes/:key", :aggregate_failures do
    context 'with an unauthorized user' do
      subject { put api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", user), params: { value: 'new' } }

      it_behaves_like 'an unauthorized API user'
    end

    context 'with an authorized user' do
      it 'creates a new custom attribute' do
        expect do
          put api("/#{attributable_name}/#{attributable.id}/custom_attributes/new", admin, admin_mode: true), params: { value: 'new' }
        end.to change { attributable.custom_attributes.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'key' => 'new', 'value' => 'new' })
        expect(attributable.custom_attributes.find_by(key: 'new').value).to eq 'new'
      end

      it 'updates an existing custom attribute' do
        expect do
          put api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", admin, admin_mode: true), params: { value: 'new' }
        end.not_to change { attributable.custom_attributes.count }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'key' => 'foo', 'value' => 'new' })
        expect(custom_attribute1.reload.value).to eq 'new'
      end

      it "returns :not_found when #{attributable_name} does not exist" do
        put api("/#{attributable_name}/#{non_existing_record_id}/custom_attributes/foo", admin, admin_mode: true), params: { value: 'new' }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "DELETE /#{attributable_name}/:id/custom_attributes/:key", :aggregate_failures do
    context 'with an unauthorized user' do
      subject { delete api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", user) }

      it_behaves_like 'an unauthorized API user'
    end

    context 'with an authorized user' do
      it 'deletes an existing custom attribute' do
        expect do
          delete api("/#{attributable_name}/#{attributable.id}/custom_attributes/foo", admin, admin_mode: true)
        end.to change { attributable.custom_attributes.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(attributable.custom_attributes.find_by(key: 'foo')).to be_nil
      end

      it "returns :not_found when #{attributable_name} does not exist" do
        delete api("/#{attributable_name}/#{non_existing_record_id}/custom_attributes/foo", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
