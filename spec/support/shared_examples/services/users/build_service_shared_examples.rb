# frozen_string_literal: true

RSpec.shared_examples 'common user build items' do
  it { is_expected.to be_valid }

  it 'sets the created_by_id' do
    expect(user.created_by_id).to eq(current_user&.id)
  end

  context 'when organization_id is in the params' do
    it 'creates personal namespace in specified organization' do
      expect(user.namespace.organization).to eq(organization)
    end
  end

  context 'when organization_id is not in the params' do
    let(:params) { base_params.except(:organization_id) }

    it 'does not assign organization' do
      expect(user.namespace.organization).to eq(nil)
    end
  end

  context 'when user_type is provided' do
    context 'when project_bot' do
      before do
        params.merge!({ user_type: :project_bot })
      end

      it { expect(user.project_bot?).to be true }
    end

    context 'when not a project_bot' do
      before do
        params.merge!({ user_type: :alert_bot })
      end

      it { expect(user).to be_human }
    end
  end
end

RSpec.shared_examples_for 'current user not admin build items' do
  context 'when "email_confirmation_setting" application setting is set to `hard`' do
    before do
      stub_application_setting_enum('email_confirmation_setting', 'hard')
      stub_application_setting(signup_enabled?: true)
    end

    it 'does not confirm the user' do
      expect(user).not_to be_confirmed
    end
  end

  context 'when "email_confirmation_setting" application setting is set to `off`' do
    before do
      stub_application_setting_enum('email_confirmation_setting', 'off')
      stub_application_setting(signup_enabled?: true)
    end

    it 'confirms the user' do
      expect(user).to be_confirmed
    end
  end

  context 'with allowed params' do
    let(:params) do
      {
        email: 1,
        name: 1,
        password: 1,
        password_automatically_set: 1,
        username: 1,
        user_type: 'project_bot',
        organization_id: organization.id
      }
    end

    let(:user_params) { params.except(:organization_id) }

    it 'sets all allowed attributes' do
      expect(User).to receive(:new).with(hash_including(user_params)).and_call_original

      user
    end
  end
end
