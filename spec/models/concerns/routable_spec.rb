require 'spec_helper'

describe Group, 'Routable' do
  let!(:group) { create(:group, name: 'foo') }

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

  describe '.member_self_and_descendants' do
    let!(:user) { create(:user) }
    let!(:nested_group) { create(:group, parent: group) }

    before { group.add_owner(user) }
    subject { described_class.member_self_and_descendants(user.id) }

    it { is_expected.to match_array [group, nested_group] }
  end

  describe '.member_hierarchy' do
    # foo/bar would also match foo/barbaz instead of just foo/bar and foo/bar/baz
    let!(:user) { create(:user) }

    #                group
    #        _______ (foo) _______
    #       |                     |
    #       |                     |
    # nested_group_1        nested_group_2
    # (bar)                 (barbaz)
    #       |                     |
    #       |                     |
    # nested_group_1_1      nested_group_2_1
    # (baz)                 (baz)
    #
    let!(:nested_group_1) { create :group, parent: group, name: 'bar' }
    let!(:nested_group_1_1) { create :group, parent: nested_group_1, name: 'baz' }
    let!(:nested_group_2) { create :group, parent: group, name: 'barbaz' }
    let!(:nested_group_2_1) { create :group, parent: nested_group_2, name: 'baz' }

    context 'user is not a member of any group' do
      subject { described_class.member_hierarchy(user.id) }

      it 'returns an empty array' do
        is_expected.to eq []
      end
    end

    context 'user is member of all groups' do
      before do
        group.add_owner(user)
        nested_group_1.add_owner(user)
        nested_group_1_1.add_owner(user)
        nested_group_2.add_owner(user)
        nested_group_2_1.add_owner(user)
      end
      subject { described_class.member_hierarchy(user.id) }

      it 'returns all groups' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the top group' do
      before { group.add_owner(user) }
      subject { described_class.member_hierarchy(user.id) }

      it 'returns all groups' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the first child (internal node), branch 1' do
      before { nested_group_1.add_owner(user) }
      subject { described_class.member_hierarchy(user.id) }

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1
        ]
      end
    end

    context 'user is member of the first child (internal node), branch 2' do
      before { nested_group_2.add_owner(user) }
      subject { described_class.member_hierarchy(user.id) }

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the last child (leaf node)' do
      before { nested_group_1_1.add_owner(user) }
      subject { described_class.member_hierarchy(user.id) }

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1
        ]
      end
    end
  end

  describe '#full_path' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }

    it { expect(group.full_path).to eq(group.path) }
    it { expect(nested_group.full_path).to eq("#{group.full_path}/#{nested_group.path}") }

    context 'with RequestStore active' do
      before do
        RequestStore.begin!
      end

      after do
        RequestStore.end!
        RequestStore.clear!
      end

      it 'does not load the route table more than once' do
        expect(group).to receive(:uncached_full_path).once.and_call_original

        3.times { group.full_path }
        expect(group.full_path).to eq(group.path)
      end
    end
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
