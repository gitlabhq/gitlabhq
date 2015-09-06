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
end
