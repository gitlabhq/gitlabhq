# frozen_string_literal: true

RSpec.shared_examples 'performs exclusions service validations' do
  subject(:execute) { service.execute }

  context 'when the integration is not instance specific', :enable_admin_mode do
    let(:integration_name) { 'mock_ci' }

    it 'returns an error response' do
      expect(execute).to be_error
      expect(execute.message).to eq('not instance specific')
    end
  end

  context 'when the user is not authorized', :enable_admin_mode do
    let(:current_user) { create(:user) }

    it 'returns an error response' do
      expect(execute).to be_error
      expect(execute.message).to eq('not authorized')
    end
  end

  context 'when a project is nil', :enable_admin_mode do
    let(:projects) { [nil] }

    it 'returns an error response' do
      expect(execute).to be_error
      expect(execute.message).to eq('not authorized')
    end
  end

  context 'when a group is nil', :enable_admin_mode do
    let(:groups) { [nil] }

    it 'returns an error response' do
      expect(execute).to be_error
      expect(execute.message).to eq('not authorized')
    end
  end
end
