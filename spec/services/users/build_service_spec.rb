# frozen_string_literal: true

require 'spec_helper'

describe Users::BuildService do
  describe '#execute' do
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
    end

    context 'with an admin user' do
      let(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, ActionController::Parameters.new(params).permit!) }

      it 'returns a valid user' do
        expect(service.execute).to be_valid
      end

      context 'calls the UpdateCanonicalEmailService' do
        specify do
          expect(Users::UpdateCanonicalEmailService).to receive(:new).and_call_original

          service.execute
        end
      end

      context 'allowed params' do
        let(:params) do
          {
            access_level: 1,
            admin: 1,
            avatar: anything,
            bio: 1,
            can_create_group: 1,
            color_scheme_id: 1,
            email: 1,
            external: 1,
            force_random_password: 1,
            hide_no_password: 1,
            hide_no_ssh_key: 1,
            linkedin: 1,
            name: 1,
            password: 1,
            password_automatically_set: 1,
            password_expires_at: 1,
            projects_limit: 1,
            remember_me: 1,
            skip_confirmation: 1,
            skype: 1,
            theme_id: 1,
            twitter: 1,
            username: 1,
            website_url: 1,
            private_profile: 1,
            organization: 1,
            location: 1,
            public_email: 1
          }
        end

        it 'sets all allowed attributes' do
          admin_user # call first so the admin gets created before setting `expect`

          expect(User).to receive(:new).with(hash_including(params)).and_call_original

          service.execute
        end
      end

      context 'with "user_default_external" application setting' do
        using RSpec::Parameterized::TableSyntax

        where(:user_default_external, :external, :email, :user_default_internal_regex, :result) do
          true  | nil   | 'fl@example.com'        | nil                     | true
          true  | true  | 'fl@example.com'        | nil                     | true
          true  | false | 'fl@example.com'        | nil                     | false

          true  | nil   | 'fl@example.com'        | ''                      | true
          true  | true  | 'fl@example.com'        | ''                      | true
          true  | false | 'fl@example.com'        | ''                      | false

          true  | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          true  | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | true
          true  | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          true  | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false

          false | nil   | 'fl@example.com'        | nil                     | false
          false | true  | 'fl@example.com'        | nil                     | true
          false | false | 'fl@example.com'        | nil                     | false

          false | nil   | 'fl@example.com'        | ''                      | false
          false | true  | 'fl@example.com'        | ''                      | true
          false | false | 'fl@example.com'        | ''                      | false

          false | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | true
          false | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          false | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          false | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
        end

        with_them do
          before do
            stub_application_setting(user_default_external: user_default_external)
            stub_application_setting(user_default_internal_regex: user_default_internal_regex)

            params.merge!({ external: external, email: email }.compact)
          end

          subject(:user) { service.execute }

          it 'correctly sets user.external' do
            expect(user.external).to eq(result)
          end
        end
      end
    end

    context 'with non admin user' do
      let(:user) { create(:user) }
      let(:service) { described_class.new(user, params) }

      it 'raises AccessDeniedError exception' do
        expect { service.execute }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'with nil user' do
      let(:service) { described_class.new(nil, params) }

      it 'returns a valid user' do
        expect(service.execute).to be_valid
      end

      context 'when "send_user_confirmation_email" application setting is true' do
        before do
          stub_application_setting(send_user_confirmation_email: true, signup_enabled?: true)
        end

        it 'does not confirm the user' do
          expect(service.execute).not_to be_confirmed
        end
      end

      context 'when "send_user_confirmation_email" application setting is false' do
        before do
          stub_application_setting(send_user_confirmation_email: false, signup_enabled?: true)
        end

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when user_type is provided' do
        subject(:user) { service.execute }

        context 'when project_bot' do
          before do
            params.merge!({ user_type: :project_bot })
          end

          it { expect(user.project_bot?).to be true}
        end

        context 'when not a project_bot' do
          before do
            params.merge!({ user_type: :alert_bot })
          end

          it { expect(user.user_type).to be nil }
        end
      end

      context 'with "user_default_external" application setting' do
        using RSpec::Parameterized::TableSyntax

        where(:user_default_external, :external, :email, :user_default_internal_regex, :result) do
          true  | nil   | 'fl@example.com'        | nil                     | true
          true  | true  | 'fl@example.com'        | nil                     | true
          true  | false | 'fl@example.com'        | nil                     | true

          true  | nil   | 'fl@example.com'        | ''                      | true
          true  | true  | 'fl@example.com'        | ''                      | true
          true  | false | 'fl@example.com'        | ''                      | true

          true  | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          true  | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          true  | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          true  | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true

          false | nil   | 'fl@example.com'        | nil                     | false
          false | true  | 'fl@example.com'        | nil                     | false
          false | false | 'fl@example.com'        | nil                     | false

          false | nil   | 'fl@example.com'        | ''                      | false
          false | true  | 'fl@example.com'        | ''                      | false
          false | false | 'fl@example.com'        | ''                      | false

          false | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          false | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          false | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
          false | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
        end

        with_them do
          before do
            stub_application_setting(user_default_external: user_default_external)
            stub_application_setting(user_default_internal_regex: user_default_internal_regex)

            params.merge!({ external: external, email: email }.compact)
          end

          subject(:user) { service.execute }

          it 'sets the value of Gitlab::CurrentSettings.user_default_external' do
            expect(user.external).to eq(result)
          end
        end
      end
    end
  end
end
