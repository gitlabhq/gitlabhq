# frozen_string_literal: true

require 'spec_helper'

describe Plan do
  describe '#default?' do
    subject { plan.default? }

    Plan.default_plans.each do |plan|
      context "when '#{plan}'" do
        let(:plan) { build("#{plan}_plan".to_sym) }

        it { is_expected.to be_truthy }
      end
    end
  end
end
