# frozen_string_literal: true

RSpec.shared_examples 'MLflow|an endpoint that requires authentication' do
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
end

RSpec.shared_examples 'MLflow|an endpoint that requires read_model_registry' do
  context 'when user does not have read_model_registry' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_registry, project)
                          .and_return(false)
    end

    it "is Not Found" do
      is_expected.to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'MLflow|an endpoint that requires write_model_registry' do
  context 'when user does not have read_model_registry' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :write_model_registry, project)
                          .and_return(false)
    end

    it "is Not Found" do
      is_expected.to have_gitlab_http_status(:unauthorized)
    end
  end
end

RSpec.shared_examples 'MLflow|Not Found - Resource Does Not Exist' do
  it "is Resource Does Not Exist", :aggregate_failures do
    is_expected.to have_gitlab_http_status(:not_found)

    expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
  end
end

RSpec.shared_examples 'MLflow|Requires api scope and write permission' do
  context 'when user has access but token has wrong scope' do
    let(:access_token) { tokens[:read] }

    it { is_expected.to have_gitlab_http_status(:forbidden) }
  end

  context 'when user has access but is not allowed to write' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :write_model_experiments, project)
                          .and_return(false)
    end

    it "is Unauthorized" do
      is_expected.to have_gitlab_http_status(:unauthorized)
    end
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
  it_behaves_like 'MLflow|an endpoint that requires authentication'

  context 'when model experiments is unavailable' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_experiments, project)
                          .and_return(false)
    end

    it "is Not Found" do
      is_expected.to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'MLflow|shared model registry error cases' do
  it_behaves_like 'MLflow|an endpoint that requires authentication'
  it_behaves_like 'MLflow|an endpoint that requires read_model_registry'
end

RSpec.shared_examples 'MLflow|Bad Request on missing required' do |keys|
  keys.each do |key|
    context "when \"#{key}\" is missing" do
      let(:params) { default_params.tap { |p| p.delete(key) } }

      it_behaves_like 'MLflow|Bad Request'
    end
  end
end

RSpec.shared_examples 'MLflow|an invalid request' do
  it_behaves_like 'MLflow|Bad Request'
end

RSpec.shared_examples 'MLflow|an authenticated resource' do
  it_behaves_like 'MLflow|an endpoint that requires authentication'
  it_behaves_like 'MLflow|Requires read_api scope'
end

RSpec.shared_examples 'MLflow|a read-only model registry resource' do
  it_behaves_like 'MLflow|an endpoint that requires authentication'
  it_behaves_like 'MLflow|an endpoint that requires read_model_registry'
end

RSpec.shared_examples 'MLflow|a read/write model registry resource' do
  it_behaves_like 'MLflow|an endpoint that requires authentication'
  it_behaves_like 'MLflow|an endpoint that requires read_model_registry'
  it_behaves_like 'MLflow|an endpoint that requires write_model_registry'
end
