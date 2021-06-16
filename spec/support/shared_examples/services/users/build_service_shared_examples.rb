# frozen_string_literal: true

RSpec.shared_examples 'common user build items' do
  it { is_expected.to be_valid }

  it 'sets the created_by_id' do
    expect(user.created_by_id).to eq(current_user&.id)
  end

  it 'calls UpdateCanonicalEmailService' do
    expect(Users::UpdateCanonicalEmailService).to receive(:new).and_call_original

    user
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
  using RSpec::Parameterized::TableSyntax

  context 'with "user_default_external" application setting' do
    where(:user_default_external, :external, :email, :user_default_internal_regex, :result) do
      true  | nil   | 'fl@example.com'        | nil                     | true
      true  | true  | 'fl@example.com'        | nil                     | true
      true  | false | 'fl@example.com'        | nil                     | true # admin difference

      true  | nil   | 'fl@example.com'        | ''                      | true
      true  | true  | 'fl@example.com'        | ''                      | true
      true  | false | 'fl@example.com'        | ''                      | true # admin difference

      true  | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
      true  | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false # admin difference
      true  | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

      true  | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
      true  | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
      true  | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true # admin difference

      false | nil   | 'fl@example.com'        | nil                     | false
      false | true  | 'fl@example.com'        | nil                     | false # admin difference
      false | false | 'fl@example.com'        | nil                     | false

      false | nil   | 'fl@example.com'        | ''                      | false
      false | true  | 'fl@example.com'        | ''                      | false # admin difference
      false | false | 'fl@example.com'        | ''                      | false

      false | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
      false | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false # admin difference
      false | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

      false | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
      false | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false # admin difference
      false | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
    end

    with_them do
      before do
        stub_application_setting(user_default_external: user_default_external)
        stub_application_setting(user_default_internal_regex: user_default_internal_regex)

        params.merge!({ external: external, email: email }.compact)
      end

      it 'sets the value of Gitlab::CurrentSettings.user_default_external' do
        expect(user.external).to eq(result)
      end
    end
  end

  context 'when "send_user_confirmation_email" application setting is true' do
    before do
      stub_application_setting(send_user_confirmation_email: true, signup_enabled?: true)
    end

    it 'does not confirm the user' do
      expect(user).not_to be_confirmed
    end
  end

  context 'when "send_user_confirmation_email" application setting is false' do
    before do
      stub_application_setting(send_user_confirmation_email: false, signup_enabled?: true)
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
        user_type: 'project_bot'
      }
    end

    it 'sets all allowed attributes' do
      expect(User).to receive(:new).with(hash_including(params)).and_call_original

      user
    end
  end
end
