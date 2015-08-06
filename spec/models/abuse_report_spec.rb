require 'rails_helper'

RSpec.describe AbuseReport, type: :model do
  subject { create(:abuse_report) }

  it { expect(subject).to be_valid }
end
