# frozen_string_literal: true

RSpec.shared_examples 'organization user creation and validation in service' do
  it 'creates organization_user on the organization', :aggregate_failures do
    organization_ids = user.organization_users.map(&:organization_id)

    expect(organization_ids).to contain_exactly(organization_params[:organization_id])
  end

  context 'when organization_params is blank' do
    let(:params) { base_params.except(*organization_params.keys) }

    it 'does not create organization_user record' do
      expect(user.organization_users).to be_empty
    end
  end

  context 'when organization param is invalid' do
    let(:params) { base_params.merge(organization_id: non_existing_record_id) }

    it 'adds invalid organization user error', :aggregate_failures do
      expect(user.valid?).to be(false)
      expect(user.errors.full_messages).to include(_('Organization users organization must exist'))
    end
  end
end

RSpec.shared_examples 'common user build items' do
  it_behaves_like 'organization user creation and validation in service'

  it { is_expected.to be_valid }

  it 'sets the created_by_id' do
    expect(user.created_by_id).to eq(current_user&.id)
  end

  it 'creates personal namespace in specified organization' do
    expect(user.namespace.organization).to eq(organization)
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
  it_behaves_like 'organization user creation and validation in service'

  context 'with organization_access_level params' do
    let(:params) { base_params.merge(organization_access_level: 'owner') }

    it 'ignores parameter and use default access level' do
      organization_user_data = user.organization_users.first

      expect(organization_user_data.access_level).to eq('default')
    end
  end

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
        email: '_email_',
        name: '_name_',
        password: 1,
        password_automatically_set: true,
        username: '_username_',
        user_type: 'project_bot',
        organization_id: organization.id
      }
    end

    let(:user_params) { params.except(:organization_id) }

    it 'sets all allowed attributes' do
      expect(user).to have_attributes(user_params)
    end
  end
end
