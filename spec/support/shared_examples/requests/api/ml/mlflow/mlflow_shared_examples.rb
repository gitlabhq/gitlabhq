# frozen_string_literal: true

RSpec.shared_examples 'MLflow|Not Found - Resource Does Not Exist' do
  it "is Resource Does Not Exist", :aggregate_failures do
    is_expected.to have_gitlab_http_status(:not_found)

    expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
  end
end

RSpec.shared_examples 'MLflow|Requires api scope' do
  context 'when user has access but token has wrong scope' do
    let(:access_token) { tokens[:read] }

    it { is_expected.to have_gitlab_http_status(:forbidden) }
  end
end

RSpec.shared_examples 'MLflow|Requires read_api scope' do
  context 'when user has access but token has wrong scope' do
    let(:access_token) { tokens[:no_access] }

    it { is_expected.to have_gitlab_http_status(:forbidden) }
  end
end

RSpec.shared_examples 'MLflow|Bad Request' do
  it "is Bad Request" do
    is_expected.to have_gitlab_http_status(:bad_request)
  end
end

RSpec.shared_examples 'MLflow|shared error cases' do
  context 'when not authenticated' do
    let(:headers) { {} }

    it "is Unauthorized" do
      is_expected.to have_gitlab_http_status(:unauthorized)
    end
  end

  context 'when user does not have access' do
    let(:access_token) { tokens[:different_user] }

    it "is Not Found" do
      is_expected.to have_gitlab_http_status(:not_found)
    end
  end

  context 'when ff is disabled' do
    let(:ff_value) { false }

    it "is Not Found" do
      is_expected.to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'MLflow|Bad Request on missing required' do |keys|
  keys.each do |key|
    context "when \"#{key}\" is missing" do
      let(:params) { default_params.tap { |p| p.delete(key) } }

      it "is Bad Request" do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
