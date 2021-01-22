# frozen_string_literal: true

RSpec.shared_examples 'creating a new HTTP integration' do
  it 'creates a new integration' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_integration = ::AlertManagement::HttpIntegration.last!
    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(new_integration).to_s)
    expect(integration_response['type']).to eq('HTTP')
    expect(integration_response['name']).to eq(new_integration.name)
    expect(integration_response['active']).to eq(new_integration.active)
    expect(integration_response['token']).to eq(new_integration.token)
    expect(integration_response['url']).to eq(new_integration.url)
    expect(integration_response['apiUrl']).to eq(nil)
  end
end

RSpec.shared_examples 'updating an existing HTTP integration' do
  it 'updates the integration' do
    post_graphql_mutation(mutation, current_user: current_user)

    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['name']).to eq('Modified Name')
    expect(integration_response['active']).to be_falsey
    expect(integration_response['url']).to include('modified-name')
  end
end

RSpec.shared_examples 'validating the payload_example' do
  context 'with invalid payloadExample attribute' do
    let(:payload_example) { 'not a JSON' }

    it 'responds with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(/was provided invalid value for payloadExample \(Invalid JSON string/)
    end
  end

  it 'validates the payload_example size' do
    allow(::Gitlab::Utils::DeepSize)
      .to receive(:new)
      .with(Gitlab::Json.parse(payload_example))
      .and_return(double(valid?: false))

    post_graphql_mutation(mutation, current_user: current_user)

    expect_graphql_errors_to_include(/payloadExample JSON is too big/)
  end
end

RSpec.shared_examples 'validating the payload_attribute_mappings' do
  context 'with invalid payloadAttributeMapping attribute does not contain fieldName' do
    let(:payload_attribute_mappings) do
      [{ path: %w[alert name], type: 'STRING' }]
    end

    it 'responds with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(/was provided invalid value for payloadAttributeMappings\.0\.fieldName \(Expected value to not be null/)
    end
  end

  context 'with invalid payloadAttributeMapping attribute does not contain path' do
    let(:payload_attribute_mappings) do
      [{ fieldName: 'TITLE', type: 'STRING' }]
    end

    it 'responds with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(/was provided invalid value for payloadAttributeMappings\.0\.path \(Expected value to not be null/)
    end
  end

  context 'with invalid payloadAttributeMapping attribute does not contain type' do
    let(:payload_attribute_mappings) do
      [{ fieldName: 'TITLE', path: %w[alert name] }]
    end

    it 'responds with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(/was provided invalid value for payloadAttributeMappings\.0\.type \(Expected value to not be null/)
    end
  end
end
