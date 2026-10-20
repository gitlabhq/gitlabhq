# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::FeatureLibrary::CurrentPlanContext, feature_category: :onboarding do
  subject(:plan_context) { described_class.new(resource: build_stubbed(:group)) }

  it 'describes a Free self-managed viewer' do
    expect(plan_context.to_h).to include(deployment: :self_managed, current_plan: :free, base_plan: :free, trial: false)
  end

  it 'reports the CE edition', unless: Gitlab.ee? do
    expect(plan_context.edition).to eq(:ce)
  end

  it 'offers both Explore pages' do
    expect(plan_context.tier_pages).to eq(%i[premium ultimate])
  end

  describe '#tier_pages' do
    using RSpec::Parameterized::TableSyntax

    where(:base_plan, :pages) do
      :free     | %i[premium ultimate]
      :premium  | %i[ultimate]
      :ultimate | %i[]
    end

    with_them do
      before do
        allow(plan_context).to receive(:base_plan).and_return(base_plan)
      end

      it { expect(plan_context.tier_pages).to eq(pages) }
    end
  end
end
