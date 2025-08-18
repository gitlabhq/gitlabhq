# frozen_string_literal: true

RSpec.shared_examples 'fetches labels' do
  it 'returns correct labels' do
    request

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response).to all(match_schema('public_api/v4/labels/label'))
    expect(json_response.size).to eq(expected_labels.size)
    expect(json_response.pluck('name')).to match_array(expected_labels)
  end
end

RSpec.shared_examples 'updating labels archived status', :aggregate_failures do
  it "returns 200 if archived status is changed to true" do
    put api_path, params: { archived: true }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['archived']).to be_truthy
    expect(label.reload.archived).to be_truthy
  end

  it "returns 200 if archived status is changed to false" do
    put api_path, params: { archived: false }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['archived']).to be_falsey
    expect(label.reload.archived).to be_falsey
  end

  context 'when :labels_archive feature flag is disabled' do
    before do
      stub_feature_flags(labels_archive: false)
    end

    it "ignores archived parameter" do
      original_archived_status = label.archived

      put api_path, params: { archived: !original_archived_status }

      expect(json_response).not_to have_key('archived')
      expect(label.reload.archived).to eq(original_archived_status)
    end
  end
end

RSpec.shared_examples 'ignores archived param when feature flag is disabled' do
  before do
    stub_feature_flags(labels_archive: false)
  end

  it 'ignores archived param', :aggregate_failures do
    post api_path,
      params: {
        name: label_title,
        color: '#FFAABB',
        archived: true
      }

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['archived']).to be_falsey
  end
end
