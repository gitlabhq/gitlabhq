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

  describe '.uids_for_names' do
    it 'returns the matching uids for the given names' do
      expect(described_class.uids_for_names(%w[free premium])).to match_array([2, 5])
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
