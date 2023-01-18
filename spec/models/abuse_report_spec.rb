# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  let_it_be(:report, reload: true) { create(:abuse_report) }
  let_it_be(:user, reload: true) { create(:admin) }

  subject { report }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User') }
    it { is_expected.to belong_to(:user) }

    it "aliases reporter to author" do
      expect(subject.author).to be(subject.reporter)
    end
  end

  describe 'validations' do
    let(:http)  { 'http://gitlab.com' }
    let(:https) { 'https://gitlab.com' }
    let(:ftp)   { 'ftp://example.com' }
    let(:javascript) { 'javascript:alert(window.opener.document.location)' }

    it { is_expected.to validate_presence_of(:reporter) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:category) }

    it do
      is_expected.to validate_uniqueness_of(:user_id)
        .scoped_to([:reporter_id, :category])
        .with_message('You have already reported this user')
    end

    it { is_expected.to validate_length_of(:reported_from_url).is_at_most(512).allow_blank }
    it { is_expected.to allow_value(http).for(:reported_from_url) }
    it { is_expected.to allow_value(https).for(:reported_from_url) }
    it { is_expected.not_to allow_value(ftp).for(:reported_from_url) }
    it { is_expected.not_to allow_value(javascript).for(:reported_from_url) }
    it { is_expected.to allow_value('http://localhost:9000').for(:reported_from_url) }
    it { is_expected.to allow_value('https://gitlab.com').for(:reported_from_url) }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      expect { subject.remove_user(deleted_by: user) }.to change { subject.user.blocked? }.to(true)
    end

    it 'lets a worker delete the user' do
      expect(DeleteUserWorker).to receive(:perform_async).with(user.id, subject.user.id, { hard_delete: true })

      subject.remove_user(deleted_by: user)
    end
  end

  describe '#notify' do
    it 'delivers' do
      expect(AbuseReportMailer).to receive(:notify).with(subject.id)
        .and_return(spy)

      subject.notify
    end

    it 'returns early when not persisted' do
      report = build(:abuse_report)

      expect(AbuseReportMailer).not_to receive(:notify)

      report.notify
    end
  end

  describe 'enums' do
    let(:categories) do
      {
        spam: 1,
        offensive: 2,
        phishing: 3,
        crypto: 4,
        credentials: 5,
        copyright: 6,
        malware: 7,
        other: 8
      }
    end

    it { is_expected.to define_enum_for(:category).with_values(**categories) }
  end
end
