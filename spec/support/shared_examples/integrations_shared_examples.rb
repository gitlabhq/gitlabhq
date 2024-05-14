# frozen_string_literal: true

RSpec.shared_examples 'set up an integration' do |endpoint:, integration:|
  include_context 'with integration'

  let(:integration_attrs) { attributes_for(integration_factory).without(:active, :type) }
  let(:url) { api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user) }

  subject(:request) { put url, params: integration_attrs }

  it "updates #{integration} settings and returns the correct fields" do
    request

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['slug']).to eq(dashed_integration)

    current_integration = project.integrations.first
    expect(current_integration).to have_attributes(integration_attrs)
    expect(json_response['properties'].keys).to match_array(current_integration.api_field_names)
    expect(json_response['properties'].keys).not_to include(*current_integration.secret_fields)
  end

  context 'when all booleans are flipped' do
    it "updates #{integration} settings and returns the correct fields" do
      flipped_attrs = integration_attrs.transform_values do |value|
        [true, false].include?(value) ? !value : value
      end

      put url, params: flipped_attrs

      expect(response).to have_gitlab_http_status(:ok)
      expect(project.integrations.first).to have_attributes(flipped_attrs)
    end
  end

  it 'returns if required fields missing' do
    required_attributes = integration_attrs_list.select do |attr|
      integration_klass.validators_on(attr).any? do |v|
        v.instance_of?(ActiveRecord::Validations::PresenceValidator) &&
          # exclude presence validators with conditional since those are not really required
          v.options.exclude?(:if) && v.options.exclude?(:unless)
      end
    end

    if required_attributes.empty?
      expected_code = :ok
    else
      integration_attrs.delete(required_attributes.sample)
      expected_code = :bad_request
    end

    put url, params: integration_attrs

    expect(response).to have_gitlab_http_status(expected_code)
  end

  context 'when an integration is disabled' do
    before do
      allow(Integration).to receive(:disabled_integration_names).and_return([integration.to_param])
    end

    it 'returns bad request' do
      put url, params: integration_attrs

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'when an integration is disabled at the project-level' do
    before do
      allow_next_found_instance_of(Project) do |project|
        allow(project).to receive(:disabled_integrations).and_return([integration])
      end
    end

    it 'returns bad request' do
      put url, params: integration_attrs

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end

RSpec.shared_examples 'disable an integration' do |endpoint:, integration:|
  include_context 'with integration'

  let_it_be(:project2) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  before do
    create(integration_factory, project: project)
  end

  it "deletes #{integration}" do
    delete api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:no_content)
    project.send(integration_method).reload
    expect(project.send(integration_method).activated?).to be_falsey
  end

  it 'returns not found if integration does not exist' do
    delete api("/projects/#{project2.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Integration Not Found')
  end
end

RSpec.shared_examples 'get an integration settings' do |endpoint:, integration:|
  include_context 'with integration'

  let!(:initialized_integration) { create(integration_factory, project: project) }

  let_it_be(:project2) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  def deactive_integration!
    unless initialized_integration.is_a?(::Integrations::Prometheus)
      return initialized_integration.update!(active: false)
    end

    # Integrations::Prometheus sets `#active` itself within a `before_save`:
    initialized_integration.manual_configuration = false
    initialized_integration.save!
  end

  it 'returns authentication error when unauthenticated' do
    get api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}")
    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it "returns all properties of active integration #{integration}, except password fields" do
    get api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user)

    expect(initialized_integration).to be_active
    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['properties'].keys).to match_array(integration_instance.api_field_names)
    expect(json_response['properties'].keys).not_to include(*integration_instance.secret_fields)
  end

  it "returns all properties of inactive integration #{integration}, except password fields" do
    deactive_integration!

    get api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user)

    expect(initialized_integration).not_to be_active
    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['properties'].keys).to match_array(integration_instance.api_field_names)
    expect(json_response['properties'].keys).not_to include(*integration_instance.secret_fields)
  end

  it "returns not found if integration does not exist" do
    get api("/projects/#{project2.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Integration Not Found')
  end

  it "returns not found if integration exists but is in `Project#disabled_integrations`" do
    expect_next_found_instance_of(Project) do |project|
      expect(project).to receive(:disabled_integrations).at_least(:once).and_return([integration])
    end

    get api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Integration Not Found')
  end

  it "returns error when authenticated but not a project owner" do
    project.add_developer(user2)
    get api("/projects/#{project.id}/#{endpoint}/#{dashed_integration}", user2)

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
