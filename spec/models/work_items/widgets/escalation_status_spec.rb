# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::EscalationStatus, feature_category: :incident_management do
  let_it_be(:work_item) { create(:work_item, :incident) }

  describe '.type' do
    it { expect(described_class.type).to eq(:escalation_status) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:escalation_status) }
  end

  describe '#escalation_status' do
    subject { described_class.new(work_item).escalation_status }

    context 'when escalation status is not set' do
      it { is_expected.to be_nil }
    end

    context 'when escalation status is set' do
      before do
        create(:incident_management_issuable_escalation_status, :acknowledged, issue: work_item)
        work_item.reload
      end

      it { is_expected.to eq(:acknowledged) }
    end
  end
end
