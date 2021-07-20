# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Plan do
  describe '#default?' do
    subject { plan.default? }

    Plan.default_plans.each do |plan|
      context "when '#{plan}'" do
        let(:plan) { build("#{plan}_plan".to_sym) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#default' do
    context 'when default plan exists' do
      let!(:default_plan) { create(:default_plan) }

      it 'returns default plan' do
        expect(described_class.default).to eq(default_plan)
      end
    end

    context 'when default plan does not exist' do
      it 'creates default plan' do
        expect { described_class.default }.to change { Plan.count }.by(1)
      end

      it 'creates plan with correct attributes' do
        plan = described_class.default

        expect(plan.name).to eq(Plan::DEFAULT)
        expect(plan.title).to eq(Plan::DEFAULT.titleize)
      end
    end
  end

  context 'when updating plan limits' do
    let(:plan) { described_class.default }

    it { expect(plan).to be_persisted }

    it { expect(plan.actual_limits).not_to be_persisted }

    it 'successfully updates the limits' do
      expect(plan.actual_limits.update!(ci_instance_level_variables: 100)).to be_truthy
    end
  end
end
