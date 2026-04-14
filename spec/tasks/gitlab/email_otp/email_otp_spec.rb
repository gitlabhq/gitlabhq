# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:email_otp tasks', :silence_stdout, feature_category: :system_access do
  include StubENV

  let(:manager) { instance_spy(Tasks::Gitlab::EmailOtp::ManageEnrollment) }

  before do
    Rake.application.rake_require 'tasks/gitlab/email_otp'
    Rake::Task.define_task(:environment)

    allow(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).and_return(manager)
  end

  describe 'gitlab:email_otp:enrol' do
    let(:task) { Rake::Task['gitlab:email_otp:enrol'] }

    before do
      task.reenable
      allow(manager).to receive(:enrol)
    end

    it 'is defined' do
      expect(task).not_to be_nil
    end

    it 'calls enrol' do
      task.invoke

      expect(manager).to have_received(:enrol)
    end

    it 'creates ManageEnrollment with dry_run=true by default' do
      expect(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).with(dry_run: true)

      task.invoke
    end

    it 'passes DRY_RUN to ManageEnrollment' do
      stub_env('DRY_RUN', false)

      expect(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).with(
        dry_run: false
      )

      task.invoke
    end

    it 'parses ENROL_AT and passes to ManageEnrollment' do
      date = '2026-03-01 12:00:00'
      stub_env('ENROL_AT', date)

      expect(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).with(
        dry_run: true,
        enrol_at: DateTime.parse(date).utc
      )

      task.invoke
    end

    it 'parses EXISTING_ENROL_AT and passes to ManageEnrollment' do
      date = '2026-02-01 12:00:00'
      stub_env('EXISTING_ENROL_AT', date)

      expect(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).with(
        dry_run: true,
        existing_enrol_at: DateTime.parse(date).utc
      )

      task.invoke
    end

    it 'parses BATCH_SIZE and BATCH_SLEEP from environment' do
      stub_env('BATCH_SIZE', '500')
      stub_env('BATCH_SLEEP', '0.2')

      expect(Tasks::Gitlab::EmailOtp::ManageEnrollment).to receive(:new).with(
        dry_run: true,
        batch_size: 500,
        batch_sleep: 0.2
      )

      task.invoke
    end

    it 'validates ENROL_AT format' do
      stub_env('ENROL_AT', 'invalid-date')

      expect { task.invoke }.to raise_error(ArgumentError)
    end

    it 'validates EXISTING_ENROL_AT format' do
      stub_env('EXISTING_ENROL_AT', 'invalid-date')

      expect { task.invoke }.to raise_error(ArgumentError)
    end
  end

  describe 'gitlab:email_otp:enforce' do
    let(:task) { Rake::Task['gitlab:email_otp:enforce'] }

    before do
      task.reenable
      allow(manager).to receive(:enforce)
    end

    it 'is defined' do
      expect(task).not_to be_nil
    end

    it 'calls enforce' do
      task.invoke

      expect(manager).to have_received(:enforce)
    end
  end

  describe 'gitlab:email_otp:unenforce' do
    let(:task) { Rake::Task['gitlab:email_otp:unenforce'] }

    before do
      task.reenable
      allow(manager).to receive(:unenforce)
    end

    it 'is defined' do
      expect(task).not_to be_nil
    end

    it 'calls unenforce' do
      task.invoke

      expect(manager).to have_received(:unenforce)
    end
  end
end
