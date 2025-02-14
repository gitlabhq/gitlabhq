# frozen_string_literal: true

RSpec.shared_examples 'set up an integration' do |endpoint:, integration:, parent_resource_name:|
  include_context 'with integration'

  let(:integrations_map) { raise NotImplementedError, 'Define `integrations_map` in the calling context' }
  let(:parent_resource) { raise NotImplementedError, 'Define `parent_resource` in the calling context' }

  let(:integration_attrs) do
    attributes_for(integration_factory).without(:active, :type)
  end

  let(:url) { api("/#{parent_resource_name.pluralize}/#{parent_resource.id}/#{endpoint}/#{dashed_integration}", user) }

  subject(:request) { put url, params: integration_attrs }

  it "updates #{integration} settings and returns the correct fields" do
    request

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['slug']).to eq(dashed_integration)

    current_integration = parent_resource.integrations.by_name(integration).first
    expect(current_integration).to have_attributes(integration_attrs)
    expect(json_response['properties'].keys).to match_array(current_integration.api_field_names)

    unless current_integration.secret_fields.empty?
      expect(json_response['properties'].keys).not_to include(*current_integration.secret_fields)
    end
  end

  context 'when all booleans are flipped' do
    it "updates #{integration} settings and returns the correct fields" do
      flipped_attrs = integration_attrs.transform_values do |value|
        [true, false].include?(value) ? !value : value
      end

      put url, params: flipped_attrs

      expect(response).to have_gitlab_http_status(:ok)
      expect(parent_resource.integrations.by_name(integration).first).to have_attributes(flipped_attrs)
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

  context "when updates fails" do
    before do
      allow_next_instance_of(::Integrations::UpdateService) do |instance|
        allow(instance).to receive(:execute).and_return(
          instance_double(ServiceResponse, success?: false, message: 'Update failed')
        )
      end
    end

    it 'returns 400 with correct message' do
      request

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to eq('Update failed')
    end
  end

  context 'when the integration does not exist' do
    let(:fresh_parent_resource) { create(parent_resource_name.to_sym, owners: [user]) }
    let(:parent_resource) { fresh_parent_resource }

    it "creates #{integration} and returns the correct fields" do
      initial_count = parent_resource.integrations.by_name(integration).count
      expect(initial_count).to eq(0)

      request

      current_integration = parent_resource.integrations.by_name(integration).first
      manual_or_special = current_integration&.manual_activation? ||
        current_integration.is_a?(::Integrations::Prometheus)
      delta = manual_or_special ? 1 : 0

      expect(parent_resource.integrations.by_name(integration).count).to eq(initial_count + delta)

      if manual_or_special
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['slug']).to eq(dashed_integration)

        expect(current_integration).to have_attributes(integration_attrs)
        expect(json_response['properties'].keys).to match_array(current_integration.api_field_names)

        if current_integration.secret_fields.present?
          expect(json_response['properties'].keys).not_to include(*current_integration.secret_fields)
        end
      else
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
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

  if parent_resource_name == 'project'
    context 'when an integration is disabled at the parent_resource-level' do
      before do
        allow_next_found_instance_of(parent_resource.class) do |instance|
          allow(instance).to receive(:disabled_integrations).and_return([integration])
        end
      end

      it 'returns bad request' do
        put url, params: integration_attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end

RSpec.shared_examples 'disable an integration' do |endpoint:, integration:, parent_resource_name:|
  include_context 'with integration'

  let(:fresh_parent_resource) { create(parent_resource_name.to_sym, owners: [user]) }
  let(:parent_resource) { fresh_parent_resource }

  subject(:request) do
    delete api("/#{parent_resource_name.pluralize}/#{parent_resource.id}/#{endpoint}/#{dashed_integration}", user)
  end

  before do
    integrations_map[integration].update_column(:active, true)
  end

  it "deletes #{integration}" do
    expect do
      request
    end.to change {
      parent_resource.integrations.where(type_new: integration_klass.name, active: true).count
    }.from(1).to(0)

    expect(response).to have_gitlab_http_status(:no_content)
  end

  it 'returns not found if integration does not exist' do
    delete api("/#{parent_resource_name.pluralize}/#{fresh_parent_resource.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Integration Not Found')
  end
end

RSpec.shared_examples 'get an integration settings' do |endpoint:, integration:, parent_resource_name:|
  include_context 'with integration'

  let(:initialized_integration) do
    integrations_map[integration]
  end

  let(:fresh_parent_resource) { create(parent_resource_name.to_sym, owners: [user]) }
  let(:parent_resource) { fresh_parent_resource }

  subject(:request) do
    get api("/#{parent_resource_name.pluralize}/#{parent_resource.id}/#{endpoint}/#{dashed_integration}", user)
  end

  def deactive_integration!
    return initialized_integration.deactivate! unless initialized_integration.is_a?(::Integrations::Prometheus)

    # Integrations::Prometheus sets `#active` itself within a `before_save`:
    initialized_integration.manual_configuration = false
    initialized_integration.save!
  end

  def activate_integration!
    return initialized_integration.activate! unless initialized_integration.is_a?(::Integrations::Prometheus)

    # Integrations::Prometheus sets `#active` itself within a `before_save`:
    initialized_integration.manual_configuration = true
    initialized_integration.save!
  end

  context 'when the integration is not active' do
    before do
      deactive_integration!
    end

    it "returns all properties of inactive integration #{integration}, except password fields" do
      request

      expect(initialized_integration).not_to be_active
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties'].keys).to match_array(initialized_integration.api_field_names)

      unless initialized_integration.secret_fields.empty?
        expect(json_response['properties'].keys).not_to include(*initialized_integration.secret_fields)
      end
    end
  end

  context 'when the integration is active' do
    before do
      activate_integration!
    end

    it "returns all properties of active integration #{integration}, except password fields" do
      request

      expect(initialized_integration).to be_active
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties'].keys).to match_array(initialized_integration.api_field_names)

      unless initialized_integration.secret_fields.empty?
        expect(json_response['properties'].keys).not_to include(*initialized_integration.secret_fields)
      end
    end
  end

  it 'returns authentication error when unauthenticated' do
    get api("/#{parent_resource_name.pluralize}/#{fresh_parent_resource.id}/#{endpoint}/#{dashed_integration}")

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it "returns not found if integration does not exist" do
    get api("/#{parent_resource_name.pluralize}/#{fresh_parent_resource.id}/#{endpoint}/#{dashed_integration}", user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Integration Not Found')
  end

  if parent_resource_name == 'project'
    it "returns not found if integration exists but is in `#{parent_resource_name}#disabled_integrations`" do
      allow_next_found_instance_of(parent_resource.class) do |instance|
        allow(instance).to receive(:disabled_integrations).and_return([integration])
      end

      get api("/#{parent_resource_name.pluralize}/#{parent_resource.id}/#{endpoint}/#{dashed_integration}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Integration Not Found')
    end
  end

  it "returns error when authenticated but not a project owner" do
    parent_resource.add_developer(user2)

    get api("/#{parent_resource_name.pluralize}/#{parent_resource.id}/#{endpoint}/#{dashed_integration}", user2)

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
