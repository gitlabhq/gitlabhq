# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDeskSetting, feature_category: :service_desk do
  describe 'validations' do
    subject(:service_desk_setting) { create(:service_desk_setting) }

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:outgoing_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:project_key).is_at_most(255) }
    it { is_expected.to allow_value('abc123_').for(:project_key) }
    it { is_expected.not_to allow_value('abc 12').for(:project_key).with_message("can contain only lowercase letters, digits, and '_'.") }
    it { is_expected.not_to allow_value('Big val').for(:project_key) }
    it { is_expected.to validate_length_of(:custom_email).is_at_most(255) }
    it { is_expected.to validate_length_of(:custom_email_smtp_address).is_at_most(255) }
    it { is_expected.to validate_length_of(:custom_email_smtp_username).is_at_most(255) }

    describe '#custom_email_enabled' do
      it { expect(subject.custom_email_enabled).to be_falsey }
      it { expect(described_class.new(custom_email_enabled: true).custom_email_enabled).to be_truthy }
    end

    context 'when custom_email_enabled is true' do
      before do
        subject.custom_email_enabled = true
      end

      it { is_expected.to validate_presence_of(:custom_email) }
      it { is_expected.to validate_uniqueness_of(:custom_email).allow_nil }
      it { is_expected.to allow_value('support@example.com').for(:custom_email) }
      it { is_expected.to allow_value('support@xn--brggen-4ya.de').for(:custom_email) } # converted domain name with umlaut
      it { is_expected.to allow_value('support1@shop.example.com').for(:custom_email) }
      it { is_expected.to allow_value('support-shop_with.crazy-address@shop.example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('support@example@example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('support.example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('example').for(:custom_email) }
      it { is_expected.not_to allow_value('" "@example.org').for(:custom_email) }
      it { is_expected.not_to allow_value('support+12@example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('user@[IPv6:2001:db8::1]').for(:custom_email) }
      it { is_expected.not_to allow_value('"><script>alert(1);</script>"@example.org').for(:custom_email) }
      it { is_expected.not_to allow_value('file://example').for(:custom_email) }
      it { is_expected.not_to allow_value('no email at all').for(:custom_email) }

      it { is_expected.to validate_presence_of(:custom_email_smtp_username) }

      it { is_expected.to validate_presence_of(:custom_email_smtp_port) }
      it { is_expected.to validate_numericality_of(:custom_email_smtp_port).only_integer.is_greater_than(0) }

      it { is_expected.to validate_presence_of(:custom_email_smtp_address) }
      it { is_expected.to allow_value('smtp.gmail.com').for(:custom_email_smtp_address) }
      it { is_expected.not_to allow_value('https://example.com').for(:custom_email_smtp_address) }
      it { is_expected.not_to allow_value('file://example').for(:custom_email_smtp_address) }
      it { is_expected.not_to allow_value('/example').for(:custom_email_smtp_address) }
    end

    describe '.valid_issue_template' do
      let_it_be(:project) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/service_desk.md' => 'template' }) }

      it 'is not valid if template does not exist' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'invalid key')

        expect(settings).not_to be_valid
        expect(settings.errors[:issue_template_key].first).to eq('is empty or does not exist')
      end

      it 'is valid if template exists' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'service_desk')

        expect(settings).to be_valid
      end
    end
  end

  describe '.valid_project_key' do
    # Creates two projects with same full path slug
    # group1/test/one and group1/test-one will both have 'group-test-one' slug
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group, name: 'test') }
    let_it_be(:project1) { create(:project, name: 'test-one', group: group) }
    let_it_be(:project2) { create(:project, name: 'one', group: subgroup) }
    let_it_be(:project_key) { 'key' }
    let!(:setting) do
      create(:service_desk_setting, project: project1, project_key: project_key)
    end

    context 'when project_key exists' do
      it 'is valid' do
        expect(setting).to be_valid
      end
    end

    context 'when project_key is unique for every project slug' do
      it 'does not add error' do
        settings = build(:service_desk_setting, project: project2, project_key: 'otherkey')

        expect(settings).to be_valid
      end
    end

    context 'when project with same slug and settings project_key exists' do
      it 'adds error' do
        settings = build(:service_desk_setting, project: project2, project_key: project_key)

        expect(settings).to be_invalid
        expect(settings.errors[:project_key].first).to eq('already in use for another service desk address.')
      end
    end
  end

  describe 'encrypted password' do
    let_it_be(:settings) do
      create(
        :service_desk_setting,
        custom_email_enabled: true,
        custom_email: 'supersupport@example.com',
        custom_email_smtp_address: 'smtp.example.com',
        custom_email_smtp_port: 587,
        custom_email_smtp_username: 'supersupport@example.com',
        custom_email_smtp_password: 'supersecret'
      )
    end

    it 'saves and retrieves the encrypted custom email smtp password and iv correctly' do
      expect(settings.encrypted_custom_email_smtp_password).not_to be_nil
      expect(settings.encrypted_custom_email_smtp_password_iv).not_to be_nil

      expect(settings.custom_email_smtp_password).to eq('supersecret')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end
end
