# frozen_string_literal: true

require 'spec_helper'

describe Users::UpdateService do
  let(:user) { create(:user) }

  describe '#execute' do
    context 'updating name' do
      context 'when the ability to update their name is not disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: false)
        end

        it 'updates the name' do
          result = update_user(user, name: 'New Name')

          expect(result).to eq(status: :success)
          expect(user.name).to eq('New Name')
        end
      end

      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        context 'executing as a regular user' do
          it 'does not update the name' do
            result = update_user(user, name: 'New Name')

            expect(result).to eq(status: :success)
            expect(user.name).not_to eq('New Name')
          end
        end

        context 'executing as an admin user' do
          it 'updates the name' do
            admin = create(:admin)
            result = described_class.new(admin, { user: user, name: 'New Name' }).execute

            expect(result).to eq(status: :success)
            expect(user.name).to eq('New Name')
          end
        end
      end
    end

    it 'updates time preferences' do
      result = update_user(user, timezone: 'Europe/Warsaw', time_display_relative: true, time_format_in_24h: false)

      expect(result).to eq(status: :success)
      expect(user.reload.timezone).to eq('Europe/Warsaw')
      expect(user.time_display_relative).to eq(true)
      expect(user.time_format_in_24h).to eq(false)
    end

    it 'returns an error result when record cannot be updated' do
      result = {}
      expect do
        result = update_user(user, { email: 'invalid' })
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
      expect(result[:message]).to eq('Username has already been taken')
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
      expect(result[:message]).to eq("Emoji is not included in the list")
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
        update_user(user, email: 'invalid')
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
