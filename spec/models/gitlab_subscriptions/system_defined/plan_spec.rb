# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::SystemDefined::Plan, feature_category: :plan_provisioning do
  describe 'included modules' do
    subject { described_class }

    it { is_expected.to include(ActiveRecord::FixedItemsModel::Model) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'ITEMS' do
    it 'matches the plan_name_uid values defined on the Plan AR model' do
      fixed_items = described_class::ITEMS.to_h { |item| [item[:name], item[:id]] }

      expect(fixed_items).to eq(::Plan::PLAN_NAME_UID_LIST.transform_keys(&:to_s))
    end

    it 'sets title to the titleized name to match how Plan rows are seeded' do
      described_class::ITEMS.each do |item|
        expect(item[:title]).to eq(item[:name].titleize)
      end
    end
  end

  describe '.names_for_uids' do
    it 'returns the matching names for the given uids' do
      expect(described_class.names_for_uids([2, 5])).to match_array(%w[free premium])
    end

    it 'ignores unknown plan uids' do
      expect(described_class.names_for_uids([2, 999])).to match_array(['free'])
    end

    it 'returns an empty array when given no known uids' do
      expect(described_class.names_for_uids([999])).to be_empty
    end

    it 'returns an empty array when given an empty array' do
      expect(described_class.names_for_uids([])).to be_empty
    end
  end

  describe 'DEFAULT' do
    it 'matches the legacy Plan default name' do
      expect(described_class::DEFAULT).to eq(::Plan::DEFAULT)
    end
  end

  describe '.default' do
    it 'returns the default plan item' do
      expect(described_class.default).to have_attributes(id: 1, name: 'default')
    end
  end

  describe '.all_plans' do
    it 'includes the default plan name' do
      expect(described_class.all_plans).to include('default')
    end
  end

  describe '.default_plans' do
    it 'includes the default plan name' do
      expect(described_class.default_plans).to include('default')
    end

    it 'is a subset of all_plans' do
      expect(described_class.all_plans).to include(*described_class.default_plans)
    end
  end

  describe '#default?' do
    it 'is true for the default plan' do
      expect(described_class.default.default?).to be(true)
    end

    it 'is false for a paid plan name' do
      expect(described_class.find_by!(name: 'premium').default?).to be(false)
    end
  end

  describe '#paid?' do
    it 'is false for the default plan' do
      expect(described_class.default.paid?).to be(false)
    end
  end

  describe '#ultimate_or_ultimate_trial_plans?' do
    it 'is false for the default plan' do
      expect(described_class.default.ultimate_or_ultimate_trial_plans?).to be(false)
    end
  end

  describe '#plan_name_uid_before_type_cast' do
    it 'returns the id like the legacy enum reader so call sites can swap one-for-one' do
      expect(described_class.find_by!(name: 'premium').plan_name_uid_before_type_cast).to eq(5)
    end
  end

  describe '#actual_limits' do
    context 'when a plan_limits row exists for the plan uid' do
      it 'returns the row for the plan uid' do
        plan_limits = create(:plan_limits)
        premium = described_class.find_by!(name: 'premium')
        create(:plan_limits, plan: create(:plan, name: premium.name), plan_name_uid: premium.id)

        expect(described_class.default.actual_limits).to eq(plan_limits)
      end
    end

    context 'when no plan_limits row exists for the plan uid' do
      it 'returns an unpersisted PlanLimits with the plan uid set' do
        limits = described_class.find_by!(name: 'opensource').actual_limits

        expect(limits).to be_a(PlanLimits)
        expect(limits).not_to be_persisted
        expect(limits.plan_name_uid).to eq(11)
      end
    end

    context 'when the request store is active', :request_store do
      it 'returns the same object and issues no further queries within the request', :aggregate_failures do
        plan = described_class.default
        first = plan.actual_limits

        expect(plan.actual_limits).to equal(first)
        expect { plan.actual_limits }.not_to exceed_query_limit(0)
      end

      it 'caches per plan' do
        described_class.default.actual_limits

        expect(described_class.find_by!(name: 'premium').actual_limits.plan_name_uid).to eq(5)
      end
    end
  end

  describe '.uids_for_names' do
    it 'returns the matching uids for the given names' do
      expect(described_class.uids_for_names(%w[free premium])).to match_array([2, 5])
    end

    it 'accepts a single name and symbols' do
      expect(described_class.uids_for_names('premium')).to match_array([5])
      expect(described_class.uids_for_names(:premium)).to match_array([5])
      expect(described_class.uids_for_names([:free, 'premium'])).to match_array([2, 5])
    end

    it 'ignores unknown plan names' do
      expect(described_class.uids_for_names(%w[free unknown_plan])).to match_array([2])
    end

    it 'returns an empty array when given no known names' do
      expect(described_class.uids_for_names(%w[unknown_plan])).to be_empty
    end

    it 'returns an empty array when given an empty array' do
      expect(described_class.uids_for_names([])).to be_empty
    end
  end
end
