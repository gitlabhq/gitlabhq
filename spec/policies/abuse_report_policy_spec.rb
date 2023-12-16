# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportPolicy, feature_category: :insider_threat do
  let(:abuse_report) { build_stubbed(:abuse_report) }

  subject(:policy) { described_class.new(user, abuse_report) }

  context 'when the user is not an admin' do
    let(:user) { create(:user) }

    it 'cannot read_abuse_report' do
      expect(policy).to be_disallowed(:read_abuse_report)
      expect(policy).to be_disallowed(:read_note)
      expect(policy).to be_disallowed(:create_note)
    end
  end

  context 'when the user is an admin', :enable_admin_mode do
    let(:user) { create(:admin) }

    it 'can read_abuse_report' do
      expect(policy).to be_allowed(:read_abuse_report)
      expect(policy).to be_allowed(:read_note)
      expect(policy).to be_allowed(:create_note)
    end
  end
end
