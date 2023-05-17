# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateService, feature_category: :user_profile do
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

    context 'updating canonical email' do
      context 'if email was changed' do
        subject do
          update_user(user, email: 'user+extrastuff@example.com', validation_password: password)
        end

        it 'calls canonicalize_email' do
          expect_next_instance_of(Users::UpdateCanonicalEmailService) do |service|
            expect(service).to receive(:execute)
          end

          subject
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
        it 'skips update canonicalize email service call' do
          expect do
            update_user(user, job_title: 'supreme leader of the universe')
          end.not_to change { user.user_canonical_email }
        end

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

      it 'does not remove followers/followees if feature flag is off' do
        stub_feature_flags(disable_follow_users: false)

        expect do
          update_user(user, enabled_following: false)
        end.to not_change { user.followed_users.count }
                                                   .and not_change { user.following_users.count }
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
