# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateService, feature_category: :user_profile do
  include AdminModeHelper

  let(:password) { User.random_password }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  describe '#execute' do
    it 'updates time preferences' do
      result = update_user(user, timezone: 'Europe/Warsaw', time_display_relative: true)

      expect(result).to eq(status: :success)
      expect(user.reload.timezone).to eq('Europe/Warsaw')
      expect(user.time_display_relative).to eq(true)
    end

    it 'returns an error result when record cannot be updated' do
      result = {}
      expect do
        result = update_user(user, { email: 'invalid', validation_password: password })
      end.not_to change { user.reload.email }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Email is invalid')
    end

    it 'includes namespace error messages' do
      create(:group, path: 'taken')
      result = {}
      expect do
        result = update_user(user, { username: 'taken' })
      end.not_to change { user.reload.username }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('A user, alias, or group already exists with that username.')
    end

    it 'updates the status if status params were given' do
      update_user(user, status: { message: "On a call" })

      expect(user.status.message).to eq("On a call")
    end

    it 'does not delete the status if no status param was passed' do
      create(:user_status, user: user, message: 'Busy!')

      update_user(user, name: 'New name')

      expect(user.status.message).to eq('Busy!')
    end

    it 'includes status error messages' do
      result = update_user(user, status: { emoji: "Moo!" })

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq("Emoji is not a valid emoji name")
    end

    it 'updates user detail with provided attributes' do
      result = update_user(user, job_title: 'Backend Engineer')

      expect(result).to eq(status: :success)
      expect(user.job_title).to eq('Backend Engineer')
    end

    context 'updating email' do
      context 'if email was changed' do
        subject do
          update_user(user, email: 'user+extrastuff@example.com', validation_password: password)
        end

        context 'when race condition' do
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/382957
          it 'updates email for stale user', :aggregate_failures do
            unconfirmed_email = 'unconfirmed-email-user-has-access-to@example.com'
            forgery_email = 'forgery@example.com'

            user.update!(email: unconfirmed_email)

            stale_user = User.find(user.id)

            service1 = described_class.new(stale_user, { email: unconfirmed_email }.merge(user: stale_user))

            service2 = described_class.new(user, { email: forgery_email }.merge(user: user))

            service2.execute
            reloaded_user = User.find(user.id)
            expect(reloaded_user.unconfirmed_email).to eq(forgery_email)
            expect(stale_user.confirmation_token).not_to eq(user.confirmation_token)
            expect(reloaded_user.confirmation_token).to eq(user.confirmation_token)

            service1.execute
            reloaded_user = User.find(user.id)
            expect(reloaded_user.unconfirmed_email).to eq(unconfirmed_email)
            expect(stale_user.confirmation_token).not_to eq(user.confirmation_token)
            expect(reloaded_user.confirmation_token).to eq(stale_user.confirmation_token)
          end
        end

        context 'when check_password is true' do
          def update_user(user, opts)
            described_class.new(user, opts.merge(user: user)).execute(check_password: true)
          end

          it 'returns error if no password confirmation was passed', :aggregate_failures do
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com' })
            end.not_to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Invalid password')
          end

          it 'returns error if wrong password confirmation was passed', :aggregate_failures do
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com', validation_password: 'wrongpassword' })
            end.not_to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Invalid password')
          end

          it 'does not require password if it was automatically set', :aggregate_failures do
            user.update!(password_automatically_set: true)
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com' })
            end.to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:success)
          end

          it 'does not require a password if the attribute changed does not require it' do
            result = {}

            expect do
              result = update_user(user, { job_title: 'supreme leader of the universe' })
            end.to change { user.reload.job_title }
            expect(result[:status]).to eq(:success)
          end
        end
      end

      context 'when check_password is left to false' do
        it 'does not require a password check', :aggregate_failures do
          result = {}
          expect do
            result = update_user(user, { email: 'example@example.com' })
          end.to change { user.reload.unconfirmed_email }
          expect(result[:status]).to eq(:success)
        end
      end

      context 'if email was NOT changed' do
        it 'does not reset unconfirmed email' do
          unconfirmed_email = 'unconfirmed-email@example.com'
          user.update!(email: unconfirmed_email)

          expect do
            update_user(user, job_title: 'supreme leader of the universe')
          end.not_to change { user.unconfirmed_email }
        end
      end
    end

    it 'does not try to reset unconfirmed email for a new user' do
      expect do
        update_user(build(:user), job_title: 'supreme leader of the universe')
      end.not_to raise_error
    end

    context 'when updating organization user data' do
      let_it_be(:organization) do
        create(:organization, organization_users: create_list(:organization_owner, 3))
      end

      let_it_be_with_reload(:organization_user) { organization.organization_users.first }

      shared_examples 'organization user update fails' do |error_message|
        subject(:execute) do
          described_class.new(current_user, {
            user: target_user,
            username: 'foo',
            organization_users_attributes: organization_users_attributes
          }).execute
        end

        it 'adds not found error message to user object' do
          execute

          expect(target_user.errors.full_messages).to include(error_message)
        end

        it 'returns not found error message', :aggregate_failures do
          result = execute

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(error_message)
        end

        it 'does not persist other user updates' do
          expect { execute }.not_to change { current_user.reload.username }
        end
      end

      context 'when user is admin', :enable_admin_mode do
        let_it_be(:current_user) { create(:admin) }

        let_it_be_with_reload(:target_user) { organization_user.user }
        let_it_be_with_reload(:other_organization_user) { organization.organization_users.last }

        Organizations::OrganizationUser.access_levels.each_key do |organization_access_level|
          context "when organization_access_level param is #{organization_access_level}" do
            subject(:execute) do
              described_class.new(current_user, {
                user: target_user,
                organization_users_attributes: [{
                  id: organization_user.id,
                  organization_id: organization.id,
                  access_level: organization_access_level
                }]
              }).execute
            end

            it "updates organization access level to #{organization_access_level}", :aggregate_failures do
              result = execute

              expect(result[:status]).to eq(:success), result[:message]
              expect(organization_user.reload.access_level).to eq(organization_access_level)
            end

            it 'does not modify organization record on organizations not in params' do
              expect { execute }.not_to change { other_organization_user.reload.access_level }
            end
          end
        end

        context 'when target user does not belong to the organization' do
          let_it_be(:target_user) { create(:user) }

          it 'adds user to the organization', :aggregate_failures do
            result = described_class.new(
              current_user,
              { user: target_user, organization_users_attributes: [{ organization_id: organization.id }] }
            ).execute

            expect(result[:status]).to eq(:success)
            expect(organization.user?(target_user)).to eq(true)
          end
        end

        context 'when organization does not exists' do
          let_it_be(:organization_users_attributes) { [{ organization_id: non_existing_record_id }] }

          it_behaves_like 'organization user update fails', _('Organization users organization must exist')
        end

        context 'when organization_id is blank' do
          let_it_be(:organization_users_attributes) { [{ id: organization_user.id }] }

          it_behaves_like 'organization user update fails', _('Organization ID cannot be nil')
        end

        context 'when organization_users param count exceeds limit' do
          let_it_be(:organization_users_attributes) do
            create_list(:organization_user, described_class::ORGANIZATION_USERS_LIMIT + 1, user: current_user)
              .map { |o| o.slice(:id) }
          end

          it_behaves_like 'organization user update fails', format(
            _('Cannot update more than %{limit} organization data at once'),
            limit: described_class::ORGANIZATION_USERS_LIMIT
          )
        end
      end

      context 'when user is non-admin' do
        let_it_be(:current_user) { organization_user.user }
        let_it_be(:target_user) { organization_user.user }
        let_it_be(:organization_users_attributes) do
          [{ id: organization_user.id, organization_id: organization.id }]
        end

        it_behaves_like 'organization user update fails', _('Insufficient permission to modify user organizations')
      end
    end

    describe 'updates the enabled_following' do
      let(:user) { create(:user) }

      before do
        3.times do
          user.follow(create(:user))
          create(:user).follow(user)
        end
        user.reload
      end

      it 'removes followers and followees' do
        expect do
          update_user(user, enabled_following: false)
        end.to change { user.followed_users.count }.from(3).to(0)
                                                   .and change { user.following_users.count }.from(3).to(0)
        expect(user.enabled_following).to eq(false)
      end

      context 'when there is more followers/followees then batch limit' do
        before do
          stub_env('BATCH_SIZE', 1)
        end

        it 'removes followers and followees' do
          expect do
            update_user(user, enabled_following: false)
          end.to change { user.followed_users.count }.from(3).to(0)
                                                     .and change { user.following_users.count }.from(3).to(0)
          expect(user.enabled_following).to eq(false)
        end
      end
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute
    end
  end

  describe '#execute!' do
    it 'updates the name' do
      service = described_class.new(user, user: user, name: 'New Name')
      expect(service).not_to receive(:notify_new_user)

      result = service.execute!

      expect(result).to be true
      expect(user.name).to eq('New Name')
    end

    it 'raises an error when record cannot be updated' do
      expect do
        update_user(user, email: 'invalid', validation_password: password)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fires system hooks when a new user is saved' do
      system_hook_service = spy(:system_hook_service)
      user = build(:user)
      service = described_class.new(user, user: user, name: 'John Doe')
      expect(service).to receive(:notify_new_user).and_call_original
      expect(service).to receive(:system_hook_service).and_return(system_hook_service)

      service.execute

      expect(system_hook_service).to have_received(:execute_hooks_for).with(user, :create)
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute!
    end
  end
end
