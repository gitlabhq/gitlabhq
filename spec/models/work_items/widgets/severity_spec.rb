# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Severity, feature_category: :incident_management do
  let_it_be(:work_item) { create(:work_item, :incident) }

  describe '.type' do
    it { expect(described_class.type).to eq(:severity) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:severity) }
  end

  describe '#severity' do
    subject { described_class.new(work_item).severity }

    context 'when severity is not set' do
      it { is_expected.to eq(IssuableSeverity::DEFAULT) }
    end

    context 'when severity is set' do
      before do
        create(:issuable_severity, issue: work_item, severity: :critical)
        work_item.reload
      end

      it { is_expected.to eq('critical') }
    end
  end
end
