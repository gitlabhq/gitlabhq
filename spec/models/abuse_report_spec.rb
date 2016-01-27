# == Schema Information
#
# Table name: abuse_reports
#
#  id          :integer          not null, primary key
#  reporter_id :integer
#  user_id     :integer
#  message     :text
#  created_at  :datetime
#  updated_at  :datetime
#

require 'rails_helper'

RSpec.describe AbuseReport, type: :model do
  subject { create(:abuse_report) }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User') }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reporter) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_uniqueness_of(:user_id).with_message('has already been reported') }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      report = build(:abuse_report)

      allow(report.user).to receive(:destroy)

      expect { report.remove_user }.to change { report.user.blocked? }.to(true)
    end

    it 'removes the user' do
      report = build(:abuse_report)

      expect { report.remove_user }.to change { User.count }.by(-1)
    end
  end

  describe '#notify' do
    it 'delivers' do
      expect(AbuseReportMailer).to receive(:notify).with(subject.id).
        and_return(spy)

      subject.notify
    end

    it 'returns early when not persisted' do
      report = build(:abuse_report)

      expect(AbuseReportMailer).not_to receive(:notify)

      report.notify
    end
  end
end
