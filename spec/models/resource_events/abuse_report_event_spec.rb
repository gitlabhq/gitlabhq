# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::AbuseReportEvent, feature_category: :instance_resiliency, type: :model do
  include ResourceEvents::AbuseReportEventsHelper

  subject(:event) { build(:abuse_report_event) }

  describe 'associations' do
    it { is_expected.to belong_to(:abuse_report).required }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:action) }
  end

  describe '#success_message' do
    it 'returns a success message for the action' do
      expect(event.success_message).to eq(success_message_for_action(event.action))
    end
  end
end
