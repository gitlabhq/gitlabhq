# frozen_string_literal: true

RSpec.shared_examples 'GET #show lists all variables' do
  it 'renders the variables as json' do
    subject

    expect(response).to match_response_schema('variables')
  end

  it 'has only one variable' do
    subject

    expect(json_response['variables'].count).to eq(1)
  end
end

RSpec.shared_examples 'PATCH #update updates variables' do
  let(:variable_attributes) do
    { id: variable.id,
      key: variable.key,
      secret_value: variable.value,
      protected: variable.protected?.to_s,
      raw: (!variable.raw?).to_s }
  end

  let(:new_variable_attributes) do
    { key: 'new_key',
      secret_value: 'dummy_value',
      protected: 'false',
      raw: 'true' }
  end

  let(:variables_scope) { owner.variables }
  let(:file_variables_scope) { owner.variables.file }

  context 'with invalid new variable parameters' do
    let(:variables_attributes) do
      [
        variable_attributes.merge(secret_value: 'other_value'),
        new_variable_attributes.merge(key: '...?')
      ]
    end

    it 'does not update the existing variable' do
      expect { subject }.not_to change { variable.reload.value }
    end

    it 'does not create the new variable' do
      expect { subject }.not_to change { variables_scope.count }
    end

    it 'returns a bad request response' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'with duplicate new variable parameters' do
    let(:variables_attributes) do
      [
        new_variable_attributes,
        new_variable_attributes.merge(secret_value: 'other_value')
      ]
    end

    it 'does not update the existing variable' do
      expect { subject }.not_to change { variable.reload.value }
    end

    it 'does not create the new variable' do
      expect { subject }.not_to change { variables_scope.count }
    end

    it 'returns a bad request response' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'with valid new variable parameters' do
    let(:variables_attributes) do
      [
        variable_attributes.merge(secret_value: 'other_value', description: 'other_description'),
        new_variable_attributes
      ]
    end

    it 'updates the existing variable' do
      old_raw = variable.raw

      subject

      variable.reload
      expect(variable.value).to eq('other_value')
      expect(variable.description).to eq('other_description')
      expect(variable.raw?).not_to be(old_raw)
    end

    it 'creates the new variable' do
      expect { subject }.to change { variables_scope.count }.by(1)
    end

    it 'returns a successful response' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'has all variables in response' do
      subject

      expect(response).to match_response_schema('variables')
    end
  end

  context 'with a deleted variable' do
    let(:variables_attributes) { [variable_attributes.merge(_destroy: 'true')] }

    it 'destroys the variable' do
      expect { subject }.to change { variables_scope.count }.by(-1)
      expect { variable.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'returns a successful response' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'has all variables in response' do
      subject

      expect(response).to match_response_schema('variables')
    end
  end

  context 'with missing variable' do
    let(:variables_attributes) do
      [variable_attributes.merge(_destroy: 'true', id: 'some-id')]
    end

    it 'returns not found response' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'for variables of type file' do
    let(:variables_attributes) do
      [
        new_variable_attributes.merge(variable_type: 'file')
      ]
    end

    it 'creates new variable of type file' do
      expect { subject }.to change { file_variables_scope.count }.by(1)
    end
  end
end
