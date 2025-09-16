# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDesk::CustomEmail, feature_category: :service_desk do
  include SentNotificationHelpers

  let_it_be(:project) { create(:project) }

  let(:sent_notification) { create_sent_notification(project: project) }
  let(:reply_key) { sent_notification.partitioned_reply_key }
  let(:custom_email) { 'support@example.com' }
  let(:custom_email_with_verification_subaddress) { 'support+verify@example.com' }
  let(:email_with_reply_key) { "support+#{reply_key}@example.com" }
  let(:project_mail_key) { ::ServiceDesk::Emails.new(project).default_subaddress_part }

  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@example.com")
  end

  describe '.reply_address' do
    subject(:reply_address) { described_class.reply_address(nil, nil) }

    it { is_expected.to be_nil }

    context 'with reply key' do
      subject(:reply_address) { described_class.reply_address(nil, reply_key) }

      it { is_expected.to be_nil }

      context 'with issue' do
        let_it_be(:issue) { create(:issue, project: project) }

        subject(:reply_address) { described_class.reply_address(issue, reply_key) }

        it { is_expected.to be_nil }

        context 'with service_desk_setting and custom email' do
          let!(:service_desk_setting) { create(:service_desk_setting, custom_email: custom_email, project: project) }

          it { is_expected.to eq(email_with_reply_key) }
        end
      end
    end
  end

  describe '.key_from_reply_address' do
    let(:email) { email_with_reply_key }

    subject(:reply_address) { described_class.key_from_reply_address(email) }

    it { is_expected.to be_nil }

    context 'with service_desk_setting' do
      let_it_be_with_refind(:setting) do
        create(:service_desk_setting, project: project, add_external_participants_from_cc: true)
      end

      it { is_expected.to be_nil }

      context 'with custom email' do
        let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
        let!(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }

        before do
          project.reset
          setting.update!(custom_email: 'support@example.com', custom_email_enabled: true)
        end

        it { is_expected.to eq(reply_key) }

        context 'when a legacy reply_key is used' do
          let(:sent_notification) { create_sent_notification(:legacy_reply_key, project: project) }
          let(:reply_key) { sent_notification.reply_key }

          it { is_expected.to eq(reply_key) }
        end
      end
    end

    context 'without reply key' do
      let(:email) { custom_email }

      it { is_expected.to be_nil }
    end
  end

  describe '.key_from_settings' do
    subject(:mail_key) { described_class.key_from_settings(email) }

    let(:email) { nil }

    it { is_expected.to be_nil }

    context 'with service desk incoming email' do
      let(:email) { ::ServiceDesk::Emails.new(project).send(:incoming_address) }

      it { is_expected.to be_nil }
    end

    context 'with another unknown email' do
      let(:email) { 'unknown@example.com' }

      it { is_expected.to be_nil }
    end

    context 'with custom email' do
      let_it_be_with_refind(:setting) do
        create(:service_desk_setting, project: project)
      end

      let_it_be(:credential) { build(:service_desk_custom_email_credential, project: project).save!(validate: false) }
      let_it_be(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }

      let(:email) { custom_email }

      before do
        project.reset
        setting.update!(custom_email: 'support@example.com') # Doesn't need to be enabled
      end

      it { is_expected.to eq(project_mail_key) }

      context 'with a custom email verification email' do
        let(:email) { custom_email_with_verification_subaddress }

        it { is_expected.to eq(project_mail_key) }
      end
    end
  end
end
