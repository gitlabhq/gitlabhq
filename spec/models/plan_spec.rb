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

  context 'when updating plan limits' do
    let(:plan) { described_class.default }

    it { expect(plan).to be_persisted }

    it { expect(plan.actual_limits).not_to be_persisted }

    it 'successfully updates the limits' do
      expect(plan.actual_limits.update!(ci_instance_level_variables: 100)).to be_truthy
    end
  end
end
