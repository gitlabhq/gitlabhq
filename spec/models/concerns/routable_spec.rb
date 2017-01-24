require 'spec_helper'

describe Group, 'Routable' do
  let!(:group) { create(:group) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:route) }
  end

  describe 'Associations' do
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe 'Callbacks' do
    it 'creates route record on create' do
      expect(group.route.path).to eq(group.path)
    end

    it 'updates route record on path change' do
      group.update_attributes(path: 'wow')

      expect(group.route.path).to eq('wow')
    end

    it 'ensure route path uniqueness across different objects' do
      create(:group, parent: group, path: 'xyz')
      duplicate = build(:project, namespace: group, path: 'xyz')

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Route path has already been taken, Route is invalid')
    end
  end

  describe '.find_by_full_path' do
    let!(:nested_group) { create(:group, parent: group) }

    it { expect(described_class.find_by_full_path(group.to_param)).to eq(group) }
    it { expect(described_class.find_by_full_path(group.to_param.upcase)).to eq(group) }
    it { expect(described_class.find_by_full_path(nested_group.to_param)).to eq(nested_group) }
    it { expect(described_class.find_by_full_path('unknown')).to eq(nil) }
  end

  describe '.where_full_path_in' do
    context 'without any paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in([])).to eq([])
      end
    end

    context 'without any valid paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in(%w[unknown])).to eq([])
      end
    end

    context 'with valid paths' do
      let!(:nested_group) { create(:group, parent: group) }

      it 'returns the projects matching the paths' do
        result = described_class.where_full_path_in([group.to_param, nested_group.to_param])

        expect(result).to contain_exactly(group, nested_group)
      end

      it 'returns projects regardless of the casing of paths' do
        result = described_class.where_full_path_in([group.to_param.upcase, nested_group.to_param.upcase])

        expect(result).to contain_exactly(group, nested_group)
      end
    end
  end
end
