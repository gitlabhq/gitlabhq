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
      expect(group.route.name).to eq(group.name)
    end

    it 'updates route record on path change' do
      group.update_attributes(path: 'wow', name: 'much')

      expect(group.route.path).to eq('wow')
      expect(group.route.name).to eq('much')
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

  describe '.member_descendants' do
    let!(:user) { create(:user) }
    let!(:nested_group) { create(:group, parent: group) }

    before { group.add_owner(user) }
    subject { described_class.member_descendants(user.id) }

    it { is_expected.to eq([nested_group]) }
  end

  describe '#full_path' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }

    it { expect(group.full_path).to eq(group.path) }
    it { expect(nested_group.full_path).to eq("#{group.full_path}/#{nested_group.path}") }
  end

  describe '#full_name' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }

    it { expect(group.full_name).to eq(group.name) }
    it { expect(nested_group.full_name).to eq("#{group.name} / #{nested_group.name}") }
  end
end

describe Project, 'Routable' do
  describe '#full_path' do
    let(:project) { build_stubbed(:empty_project) }

    it { expect(project.full_path).to eq "#{project.namespace.full_path}/#{project.path}" }
  end

  describe '#full_name' do
    let(:project) { build_stubbed(:empty_project) }

    it { expect(project.full_name).to eq "#{project.namespace.human_name} / #{project.name}" }
  end
end
