# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/tasks/gitlab/email_otp/manage_enrollment'

RSpec.describe Tasks::Gitlab::EmailOtp::ManageEnrollment, :silence_stdout, feature_category: :system_access do
  describe '#enrol' do
    subject(:enrol) { manager.enrol }

    let(:enrol_at) { 1.day.from_now }

    # The following 3 users can be in scope for enrollment
    let!(:in_scope_user_a) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false)
    end

    let!(:in_scope_user_b) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false)
    end

    let!(:in_scope_passwordless_user) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false).tap do |user|
        # Passkeys do not enable two-factor authentication currently.
        create(:webauthn_registration, :passkey, user: user)
      end
    end

    # The following users should not be enrolled in Email OTP
    # A FrozenError will be raised if modified
    # rubocop:disable RSpec/AvoidTestProf -- let_it_be "can dramatically speed up tests that create database models"
    let_it_be(:webauthn_2fa_user, freeze: true) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false).tap do |user|
        create(:webauthn_registration, :second_factor, user: user)
      end
    end

    let_it_be(:inactive_user, freeze: true) do
      create(:user, state: 'blocked', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false)
    end

    let_it_be(:bot_user, freeze: true) do
      create(:user, state: 'active', user_type: :project_bot, password_automatically_set: false,
        otp_required_for_login: false)
    end

    let_it_be(:auto_password_user, freeze: true) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: true, otp_required_for_login: false)
    end

    let_it_be(:totp_user, freeze: true) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false, otp_required_for_login: true)
    end

    # This use is already enrolled, and we freeze it to validate our
    # script doesn't modify them
    let_it_be(:enrolled_user, freeze: true) do
      create(:user, state: 'active', user_type: :human, password_automatically_set: false,
        otp_required_for_login: false).tap do |user|
        user.user_detail.update!(email_otp_required_after: 1.day.ago)
      end
    end
    # rubocop:enable RSpec/AvoidTestProf

    before do
      # Remove the sleep-by-default behavior during tests
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:sleep)
      end
    end

    context 'when dry_run is true' do
      let(:manager) { described_class.new(dry_run: true, enrol_at: enrol_at) }

      before do
        allow(manager).to receive(:confirm_settings)
      end

      it 'counts in-scope users without updating' do
        expect { enrol }.to output(/Batch 1: 3 rows updated/).to_stdout
      end

      it 'does not update user_details' do
        enrol

        in_scope_user_a.user_detail.reload
        expect(in_scope_user_a.user_detail.email_otp_required_after).to be_nil
      end

      it 'prints completion message with DRY RUN prefix' do
        expect { enrol }.to output(/\[DRY RUN\] ✓ Enrollment complete/).to_stdout
      end

      it 'does not sleep' do
        enrol
        expect(manager).not_to have_received(:sleep)
      end

      context 'when targeting an existing cohort for rollback/shift', :freeze_time do
        let(:existing_date) { 10.days.ago }
        let(:manager) { described_class.new(dry_run: true, enrol_at: enrol_at, existing_enrol_at: existing_date) }

        before do
          in_scope_user_a.user_detail.update!(email_otp_required_after: existing_date)
          in_scope_user_b.user_detail.update!(email_otp_required_after: existing_date)
        end

        it 'counts only users with the existing enrollment date' do
          expect { enrol }.to output(/Batch 1: 2 rows updated/).to_stdout
        end

        it 'does not update any user_details' do
          enrol

          in_scope_user_a.user_detail.reload
          expect(in_scope_user_a.user_detail.email_otp_required_after).to eq(existing_date)

          in_scope_user_b.user_detail.reload
          expect(in_scope_user_b.user_detail.email_otp_required_after).to eq(existing_date)
        end
      end
    end

    context 'when dry_run is false', :freeze_time do
      before do
        allow(manager).to receive(:confirm_settings)
      end

      shared_examples 'batches correctly' do
        it 'passes batch_size as argument to each_batch' do
          allow(User).to receive_message_chain(:active, :human, :each_batch)
          manager.enrol

          expect(User.active.human).to have_received(:each_batch).with(of: 3)
        end

        it 'does not cause N+1 queries during enrollment' do
          control = ActiveRecord::QueryRecorder.new do
            manager.enrol
          end

          # 7 active human users with batch_size 3 => 3 batches
          # To start:  1 initial query to start the boundary scan.
          # Per batch: 1 CTE query and 1 count/update query
          # Total: 1 + (3 * 2) = 7 queries
          expect(control.count).to eq 7
        end
      end

      shared_examples 'sleep and log' do
        it 'uses batch_sleep parameter' do
          enrol
          expect(manager).to have_received(:sleep).with(0.1)
        end

        it 'prints completion message without DRY RUN prefix' do
          expect { enrol }.to output(/✓ Enrollment complete/).to_stdout
        end
      end

      context 'when enrolling unenrolled users' do
        let(:manager) { described_class.new(dry_run: false, enrol_at: enrol_at) }

        it 'raises ArgumentError when enrol_at and existing_enrol_at are both nil' do
          manager = described_class.new(dry_run: false)
          expect { manager.enrol }.to raise_error(ArgumentError, /ENROL_AT is required/)
        end

        it 'updates in-scope unenrolled users', :freeze_time do
          enrol

          # Verify in-scope users are updated
          expect(in_scope_user_a.user_detail.reload.email_otp_required_after).to eq(enrol_at)
          expect(in_scope_user_b.user_detail.reload.email_otp_required_after).to eq(enrol_at)
          expect(in_scope_passwordless_user.user_detail.reload.email_otp_required_after).to eq(enrol_at)

          # Out of scope users are frozen
        end

        context 'with batch_size: 3' do
          let(:manager) { described_class.new(dry_run: false, enrol_at: enrol_at, batch_size: 3) }

          include_examples 'batches correctly'
        end

        include_examples 'sleep and log'
      end

      context 'when managing cohorts' do
        let(:existing_date) { 10.days.ago }
        let(:manager) { described_class.new(dry_run: false, enrol_at: new_date, existing_enrol_at: existing_date) }

        before do
          # Set up a cohort with the existing date
          in_scope_user_a.user_detail.update!(email_otp_required_after: existing_date)
          in_scope_user_b.user_detail.update!(email_otp_required_after: existing_date)
        end

        context 'when shifting enrollment by providing another date' do
          let(:new_date) { 2.days.from_now }

          it 'shifts the existing cohort to the new date' do
            enrol

            in_scope_user_a.user_detail.reload
            expect(in_scope_user_a.user_detail.email_otp_required_after).to eq(new_date)

            in_scope_user_b.user_detail.reload
            expect(in_scope_user_b.user_detail.email_otp_required_after).to eq(new_date)
          end

          it 'does not affect users with different enrollment dates' do
            expect { enrol }.to not_change { enrolled_user.user_detail.reload.email_otp_required_after }
          end

          context 'with batch_size: 3' do
            let(:manager) do
              described_class.new(dry_run: false, enrol_at: new_date, existing_enrol_at: existing_date, batch_size: 3)
            end

            include_examples 'batches correctly'
          end

          include_examples 'sleep and log'
        end

        context 'when un-enrolling by providing nil' do
          let(:new_date) { nil }

          before do
            # Set up a cohort with the existing date
            in_scope_user_a.user_detail.update!(email_otp_required_after: existing_date)
            in_scope_user_b.user_detail.update!(email_otp_required_after: existing_date)
          end

          it 'sets the cohort back to nil' do
            enrol

            in_scope_user_a.user_detail.reload
            expect(in_scope_user_a.user_detail.email_otp_required_after).to be_nil

            in_scope_user_b.user_detail.reload
            expect(in_scope_user_b.user_detail.email_otp_required_after).to be_nil
          end

          it 'does not affect users with different enrollment dates' do
            expect { enrol }.to not_change { enrolled_user.user_detail.reload.email_otp_required_after }
          end

          context 'with batch_size: 3' do
            let(:manager) do
              described_class.new(dry_run: false, enrol_at: new_date, existing_enrol_at: existing_date, batch_size: 3)
            end

            include_examples 'batches correctly'
          end

          include_examples 'sleep and log'
        end
      end
    end
  end

  describe '#enforce' do
    subject(:enforce) { manager.enforce }

    before do
      create(:application_setting, require_minimum_email_based_otp_for_users_with_passwords: false)
    end

    context 'when dry_run is false' do
      let(:manager) { described_class.new(dry_run: false) }

      it 'enables the instance setting' do
        enforce

        expect(ApplicationSetting.current.require_minimum_email_based_otp_for_users_with_passwords).to be true
      end

      it 'prints confirmation without DRY RUN prefix' do
        expect { enforce }.to output(/✓ Email OTP enforcement enabled/).to_stdout
      end
    end

    context 'when dry_run is true' do
      let(:manager) { described_class.new(dry_run: true) }

      it 'does not enable the instance setting' do
        enforce

        expect(ApplicationSetting.current.require_minimum_email_based_otp_for_users_with_passwords).to be false
      end

      it 'prints DRY RUN message' do
        expect { enforce }.to output(/\[DRY RUN\] Enforcing Email OTP/).to_stdout
      end
    end
  end

  describe '#unenforce' do
    subject(:unenforce) { manager.unenforce }

    before do
      create(:application_setting, require_minimum_email_based_otp_for_users_with_passwords: true)
    end

    context 'when dry_run is false' do
      let(:manager) { described_class.new(dry_run: false) }

      it 'disables the instance setting' do
        unenforce

        expect(ApplicationSetting.current.require_minimum_email_based_otp_for_users_with_passwords).to be false
      end

      it 'prints confirmation without DRY RUN prefix' do
        expect { unenforce }.to output(/✓ Email OTP enforcement disabled/).to_stdout
      end
    end

    context 'when dry_run is true' do
      let(:manager) { described_class.new(dry_run: true) }

      it 'does not disable the instance setting' do
        unenforce

        expect(ApplicationSetting.current.require_minimum_email_based_otp_for_users_with_passwords).to be true
      end

      it 'prints DRY RUN message' do
        expect { unenforce }.to output(/\[DRY RUN\] Disabling mandatory enforcement/).to_stdout
      end
    end
  end

  describe 'initialization' do
    it 'accepts all parameters' do
      enrol_at = 1.day.from_now
      existing_enrol_at = 1.day.ago
      manager = described_class.new(
        dry_run: false,
        enrol_at: enrol_at,
        existing_enrol_at: existing_enrol_at,
        batch_size: 500,
        batch_sleep: 0.5
      )

      expect(manager.instance_variable_get(:@dry_run)).to be false
      expect(manager.instance_variable_get(:@enrol_at)).to eq(enrol_at)
      expect(manager.instance_variable_get(:@existing_enrol_at)).to eq(existing_enrol_at)
      expect(manager.instance_variable_get(:@batch_size)).to eq(500)
      expect(manager.instance_variable_get(:@batch_sleep)).to eq(0.5)
    end

    it 'uses default values with no sleep when none provided' do
      manager = described_class.new

      expect(manager.instance_variable_get(:@dry_run)).to be true
      expect(manager.instance_variable_get(:@existing_enrol_at)).to be_nil
      expect(manager.instance_variable_get(:@batch_size)).to eq(1000)
      expect(manager.instance_variable_get(:@batch_sleep)).to eq(0)
    end

    it 'uses default sleep when DRY_RUN=false and none passed' do
      manager = described_class.new(dry_run: false)

      expect(manager.instance_variable_get(:@batch_sleep)).to eq(0.1)
    end
  end

  describe '#confirm_settings' do
    let(:manager) { described_class.new(dry_run: false, enrol_at: 1.day.from_now, batch_size: 500, batch_sleep: 0.2) }
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:proceed) { true }

    before do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      # Proceed past the prompt to return before an abort
      allow(prompt).to receive(:yes?).and_return(proceed)
    end

    it 'does not abort if user confirms' do
      expect { manager.send(:confirm_settings) }.not_to raise_error
    end

    it 'displays all settings' do
      expect do
        manager.send(:confirm_settings)
      end.to output(/Dry Run: No|Batch Size: 500|Sleep between batches: 0.2s/).to_stdout
    end

    it 'displays when dry-run is true' do
      manager = described_class.new(dry_run: true)
      allow(TTY::Prompt).to receive(:new).and_return(prompt)

      expect { manager.send(:confirm_settings) }.to output(/Dry Run: Yes/).to_stdout
    end

    it 'displays enrollment date' do
      enrol_at = 1.day.from_now
      manager_with_date = described_class.new(dry_run: false, enrol_at: enrol_at)

      expect { manager_with_date.send(:confirm_settings) }.to output(/Setting enrollment date: #{enrol_at}/).to_stdout
    end

    it 'displays existing enrollment date when targeting a cohort' do
      enrol_at = 1.day.from_now
      existing_date = 1.day.ago
      manager_with_dates = described_class.new(dry_run: false, enrol_at: enrol_at, existing_enrol_at: existing_date)

      expect do
        manager_with_dates.send(:confirm_settings)
      end.to output(/Applying to existing enrollment date.*target cohort.*#{existing_date}/).to_stdout
    end

    it 'checks if email_based_mfa feature flag is enabled' do
      allow(Feature).to receive(:enabled?).with(:email_based_mfa).and_return(true)

      expect { manager.send(:confirm_settings) }.to output(/Feature Flag.*email_based_mfa.*Yes/).to_stdout
    end

    it 'warns if email_based_mfa feature flag is disabled' do
      allow(Feature).to receive(:enabled?).with(:email_based_mfa).and_return(false)

      expect { manager.send(:confirm_settings) }.to output(/Feature Flag.*email_based_mfa.*No/).to_stdout
    end

    it 'prompts for confirmation' do
      manager.send(:confirm_settings)

      expect(prompt).to have_received(:yes?).with("Is this correct?", default: false)
    end

    context 'when not confirming' do
      let(:proceed) { false }

      it 'aborts' do
        expect { manager.send(:confirm_settings) }.to raise_error(SystemExit)
      end
    end
  end
end
