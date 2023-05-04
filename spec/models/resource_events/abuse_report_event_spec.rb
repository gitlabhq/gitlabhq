# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::AbuseReportEvent, feature_category: :instance_resiliency, type: :model do
  subject(:event) { build(:abuse_report_event) }

  describe 'associations' do
    it { is_expected.to belong_to(:abuse_report).required }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:action) }
  end
end
