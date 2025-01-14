# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BuildService, feature_category: :user_management do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:current_user) { nil }
    let_it_be(:organization) { create(:organization) }
    let_it_be(:organization_params) { { organization_id: organization.id, organization_access_level: 'owner' } }

    let(:base_params) do
      build_stubbed(:user)
        .slice(:first_name, :last_name, :name, :username, :email, :password)
        .merge(organization_params)
    end

    let(:params) { base_params }
    let(:service) { described_class.new(current_user, params) }

    context 'with user_detail built' do
      it 'creates the user_detail record' do
        user = service.execute

        expect { user.save! }.to change { UserDetail.count }.by(1)
      end
    end

    context 'with nil current_user' do
      subject(:user) { service.execute }

      it_behaves_like 'common user build items'
      it_behaves_like 'current user not admin build items'

      context 'with "user_default_external" application setting' do
        using RSpec::Parameterized::TableSyntax

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
    end

    context 'with non admin current_user' do
      let_it_be(:current_user) { create(:user) }

      it 'raises AccessDeniedError exception' do
        expect { described_class.new(current_user, params).execute }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'with an admin current_user' do
      let_it_be(:current_user) { create(:admin) }

      let(:service) { described_class.new(current_user, ActionController::Parameters.new(params).permit!) }

      subject(:user) { service.execute }

      it_behaves_like 'common user build items'

      it 'creates organization_user with access level from params' do
        organization_user_data = user.organization_users.first

        expect(organization_user_data.access_level).to eq(organization_params[:organization_access_level])
      end

      context 'with allowed params' do
        let(:params) do
          {
            access_level: 1,
            admin: 1,
            avatar: anything,
            bio: 1,
            bot_namespace: create(:group),
            can_create_group: 1,
            color_scheme_id: 1,
            color_mode_id: 1,
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

        let(:user_params) { params }

        it 'sets all allowed attributes' do
          expect_next_instance_of(User) do |instance|
            # Due to skip_confirmation not being an actual attribute, we need to verify this way instead
            # of checking the returned user from execute.
            expect(instance).to receive(:assign_attributes).with(hash_including(user_params)).and_call_original
          end

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
