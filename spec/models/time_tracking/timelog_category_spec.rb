# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeTracking::TimelogCategory, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).with_foreign_key('namespace_id') }
    it { is_expected.to have_many(:timelogs) }
  end

  describe 'default values' do
    it { expect(described_class.new.color).to eq(described_class::DEFAULT_COLOR) }
  end

  describe 'validations' do
    subject { create(:timelog_category) }

    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_length_of(:color).is_at_most(7) }
  end

  describe 'validations when billable' do
    subject { create(:timelog_category, billable: true, billing_rate: 10.5) }

    it { is_expected.to validate_presence_of(:billing_rate) }
    it { is_expected.to validate_numericality_of(:billing_rate).is_greater_than(0) }
  end

  describe '#name' do
    it 'strips name' do
      timelog_category = described_class.new(name: '  TimelogCategoryTest  ')
      timelog_category.valid?

      expect(timelog_category.name).to eq('TimelogCategoryTest')
    end
  end

  describe '#color' do
    it 'strips color' do
      timelog_category = described_class.new(name: 'TimelogCategoryTest', color: '  #fafafa  ')
      timelog_category.valid?

      expect(timelog_category.color).to eq(::Gitlab::Color.of('#fafafa'))
    end
  end

  describe '#find_by_name' do
    let_it_be(:namespace_a) { create(:namespace) }
    let_it_be(:namespace_b) { create(:namespace) }
    let_it_be(:timelog_category_a) { create(:timelog_category, namespace: namespace_a, name: 'TimelogCategoryTest') }

    it 'finds the correct timelog category' do
      expect(described_class.find_by_name(namespace_a.id, 'TIMELOGCATEGORYTest')).to match_array([timelog_category_a])
    end

    it 'returns empty if not found' do
      expect(described_class.find_by_name(namespace_b.id, 'TIMELOGCATEGORYTest')).to be_empty
    end
  end
end
