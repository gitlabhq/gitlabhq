# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BuildService do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:current_user) { nil }

    let(:params) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }
    let(:service) { described_class.new(current_user, params) }

    shared_examples_for 'common build items' do
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

    shared_examples_for 'current user not admin' do
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

    context 'with nil current_user' do
      subject(:user) { service.execute }

      it_behaves_like 'common build items'
      it_behaves_like 'current user not admin'
    end

    context 'with non admin current_user' do
      let_it_be(:current_user) { create(:user) }

      let(:service) { described_class.new(current_user, params) }

      subject(:user) { service.execute(skip_authorization: true) }

      it 'raises AccessDeniedError exception when authorization is not skipped' do
        expect { service.execute }.to raise_error Gitlab::Access::AccessDeniedError
      end

      it_behaves_like 'common build items'
      it_behaves_like 'current user not admin'
    end

    context 'with an admin current_user' do
      let_it_be(:current_user) { create(:admin) }

      let(:params) { build_stubbed(:user).slice(:name, :username, :email, :password) }
      let(:service) { described_class.new(current_user, ActionController::Parameters.new(params).permit!) }

      subject(:user) { service.execute }

      it_behaves_like 'common build items'

      context 'with allowed params' do
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
            public_email: 1,
            user_type: 'project_bot',
            note: 1,
            view_diffs_file_by_file: 1
          }
        end

        it 'sets all allowed attributes' do
          expect(User).to receive(:new).with(hash_including(params)).and_call_original

          service.execute
        end
      end

      context 'with "user_default_external" application setting' do
        where(:user_default_external, :external, :email, :user_default_internal_regex, :result) do
          true  | nil   | 'fl@example.com'        | nil                     | true
          true  | true  | 'fl@example.com'        | nil                     | true
          true  | false | 'fl@example.com'        | nil                     | false # admin difference

          true  | nil   | 'fl@example.com'        | ''                      | true
          true  | true  | 'fl@example.com'        | ''                      | true
          true  | false | 'fl@example.com'        | ''                      | false # admin difference

          true  | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          true  | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | true # admin difference
          true  | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          true  | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true
          true  | false | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false # admin difference

          false | nil   | 'fl@example.com'        | nil                     | false
          false | true  | 'fl@example.com'        | nil                     | true # admin difference
          false | false | 'fl@example.com'        | nil                     | false

          false | nil   | 'fl@example.com'        | ''                      | false
          false | true  | 'fl@example.com'        | ''                      | true # admin difference
          false | false | 'fl@example.com'        | ''                      | false

          false | nil   | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | true # admin difference
          false | false | 'fl@example.com'        | '^(?:(?!\.ext@).)*$\r?' | false

          false | nil   | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | false
          false | true  | 'tester.ext@domain.com' | '^(?:(?!\.ext@).)*$\r?' | true # admin difference
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
    end
  end
end
