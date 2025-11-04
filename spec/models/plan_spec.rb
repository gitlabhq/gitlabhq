# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Plan do
  describe 'validations' do
    describe 'plan_name_uid' do
      it 'validates presence on create' do
        plan = described_class.new(name: 'unknown_plan')

        expect(plan.valid?(:create)).to be_falsey
        expect(plan.errors[:plan_name_uid]).to include("can't be blank")
      end

      it 'validates uniqueness on create' do
        existing = create(:default_plan)
        duplicate = described_class.new(name: 'default', plan_name_uid: existing.plan_name_uid)

        expect(duplicate.valid?(:create)).to be_falsey
        expect(duplicate.errors[:plan_name_uid]).to include('has already been taken')
      end
    end
  end

  describe 'plan_name_uid assignment' do
    it 'is automatically set for known plans' do
      plan = described_class.new(name: 'default', title: 'Default')
      plan.save!

      expect(plan.plan_name_uid).to eq('default')
    end
  end

  describe 'scopes', :aggregate_failures do
    let_it_be(:default_plan) { create(:default_plan) }

    describe '.by_name' do
      it 'returns plans by their name' do
        expect(described_class.by_name('default')).to match_array([default_plan])
        expect(described_class.by_name(%w[default unknown])).to match_array([default_plan])
        expect(described_class.by_name(nil)).to be_empty
      end
    end
  end

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

  describe '#ids_for_names' do
    let_it_be(:default_plan) { create(:default_plan) }

    subject(:plan) { described_class.ids_for_names([default_plan.name]) }

    it { is_expected.to eq([default_plan.id]) }
  end

  describe '#names_for_ids' do
    let_it_be(:default_plan) { create(:default_plan) }

    subject(:plan) { described_class.names_for_ids([default_plan.id]) }

    it { is_expected.to eq([default_plan.name]) }
  end
end
