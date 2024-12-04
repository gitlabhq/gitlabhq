# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupGroupLink, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:nested_group) { create(:group, parent: group) }
  let_it_be(:shared_group) { create(:group) }

  describe 'validation' do
    let_it_be(:group_group_link) do
      create(:group_group_link, shared_group: shared_group, shared_with_group: group)
    end

    it { is_expected.to validate_presence_of(:shared_group) }

    it do
      is_expected.to(
        validate_uniqueness_of(:shared_group_id)
          .scoped_to(:shared_with_group_id)
          .with_message('The group has already been shared with this group'))
    end

    it { is_expected.to validate_presence_of(:shared_with_group) }
    it { is_expected.to validate_presence_of(:group_access) }

    it do
      is_expected.to(
        validate_inclusion_of(:group_access).in_array(Gitlab::Access.values))
    end
  end

  describe 'relations' do
    it { is_expected.to belong_to(:shared_group) }
    it { is_expected.to belong_to(:shared_with_group) }
  end

  describe 'scopes' do
    context 'for scopes fetching records based on access levels' do
      let_it_be(:group_group_link_guest) { create :group_group_link, :guest }
      let_it_be(:group_group_link_reporter) { create :group_group_link, :reporter }
      let_it_be(:group_group_link_developer) { create :group_group_link, :developer }
      let_it_be(:group_group_link_maintainer) { create :group_group_link, :maintainer }
      let_it_be(:group_group_link_owner) { create :group_group_link, :owner }

      describe '.non_guests' do
        it 'returns all records which are greater than Guests access' do
          expect(described_class.non_guests).to match_array([
            group_group_link_reporter, group_group_link_developer,
            group_group_link_maintainer, group_group_link_owner
          ])
        end
      end

      describe '.with_owner_or_maintainer_access' do
        it 'returns all records which have OWNER or MAINTAINER access' do
          expect(described_class.with_owner_or_maintainer_access).to match_array([
            group_group_link_maintainer,
            group_group_link_owner
          ])
        end
      end

      describe '.with_owner_access' do
        it 'returns all records which have OWNER access' do
          expect(described_class.with_owner_access).to match_array([group_group_link_owner])
        end
      end

      describe '.with_developer_access' do
        it 'returns all records which have DEVELOPER access' do
          expect(described_class.with_developer_access).to match_array([group_group_link_developer])
        end
      end

      describe '.with_developer_maintainer_owner_access' do
        it 'returns all records which have DEVELOPER, MAINTAINER or OWNER access' do
          expect(described_class.with_developer_maintainer_owner_access).to match_array([
            group_group_link_developer,
            group_group_link_owner,
            group_group_link_maintainer
          ])
        end
      end
    end

    context 'for access via group shares' do
      let_it_be(:shared_with_group_1) { create(:group) }
      let_it_be(:shared_with_group_2) { create(:group) }
      let_it_be(:shared_with_group_3) { create(:group) }
      let_it_be(:shared_group_1) { create(:group) }
      let_it_be(:shared_group_2) { create(:group) }
      let_it_be(:shared_group_3) { create(:group) }
      let_it_be(:shared_group_1_subgroup) { create(:group, parent: shared_group_1) }

      before do
        create :group_group_link, shared_with_group: shared_with_group_1, shared_group: shared_group_1
        create :group_group_link, shared_with_group: shared_with_group_2, shared_group: shared_group_2
        create :group_group_link, shared_with_group: shared_with_group_3, shared_group: shared_group_3
      end

      describe '.groups_accessible_via' do
        it 'returns other groups that you can get access to, via the group shares of the specified groups' do
          group_ids = [shared_with_group_1.id, shared_with_group_2.id]
          expected_result = Group.id_in([shared_group_1.id, shared_group_1_subgroup.id, shared_group_2.id])

          expect(described_class.groups_accessible_via(group_ids)).to match_array(expected_result)
        end
      end

      describe '.groups_having_access_to' do
        it 'returns all other groups that are having access to these specified groups, via group share' do
          group_ids = [shared_group_1.id, shared_group_2.id]
          expected_result = Group.id_in([shared_with_group_1.id, shared_with_group_2.id])

          expect(described_class.groups_having_access_to(group_ids)).to match_array(expected_result)
        end
      end
    end

    describe '.distinct_on_shared_with_group_id_with_group_access' do
      let_it_be(:sub_shared_group) { create(:group, parent: shared_group) }
      let_it_be(:other_group) { create(:group) }

      let_it_be(:group_group_link_1) do
        create(
          :group_group_link,
          shared_group: shared_group,
          shared_with_group: group,
          group_access: Gitlab::Access::DEVELOPER
        )
      end

      let_it_be(:group_group_link_2) do
        create(
          :group_group_link,
          shared_group: shared_group,
          shared_with_group: other_group,
          group_access: Gitlab::Access::GUEST
        )
      end

      let_it_be(:group_group_link_3) do
        create(
          :group_group_link,
          shared_group: sub_shared_group,
          shared_with_group: group,
          group_access: Gitlab::Access::GUEST
        )
      end

      let_it_be(:group_group_link_4) do
        create(
          :group_group_link,
          shared_group: sub_shared_group,
          shared_with_group: other_group,
          group_access: Gitlab::Access::DEVELOPER
        )
      end

      it 'returns only one group link per group (with max group access)' do
        distinct_group_group_links = described_class.distinct_on_shared_with_group_id_with_group_access

        expect(described_class.all.count).to eq(4)
        expect(distinct_group_group_links.count).to eq(2)
        expect(distinct_group_group_links).to include(group_group_link_1)
        expect(distinct_group_group_links).not_to include(group_group_link_2)
        expect(distinct_group_group_links).not_to include(group_group_link_3)
        expect(distinct_group_group_links).to include(group_group_link_4)
      end
    end

    describe '.for_shared_with_groups' do
      let_it_be(:link) { create(:group_group_link) }

      it 'returns links shared with the groups passed in' do
        expect(described_class.for_shared_with_groups(link.shared_with_group)).to contain_exactly(link)
      end
    end

    describe '.with_at_least_group_access' do
      let_it_be(:group_link_dev) { create(:group_group_link, group_access: Gitlab::Access::DEVELOPER) }
      let_it_be(:group_link_guest) { create(:group_group_link, group_access: Gitlab::Access::GUEST) }
      let_it_be(:group_link_maintainer) { create(:group_group_link, group_access: Gitlab::Access::MAINTAINER) }

      it 'filters group links with at least the specified group access' do
        results = described_class.with_at_least_group_access(Gitlab::Access::DEVELOPER)

        expect(results).to include(group_link_dev, group_link_maintainer)
        expect(results).not_to include(group_link_guest)
      end
    end
  end

  describe '#human_access' do
    it 'delegates to Gitlab::Access' do
      group_group_link = create(:group_group_link, :reporter)
      expect(Gitlab::Access).to receive(:human_access).with(group_group_link.group_access)

      group_group_link.human_access
    end
  end

  describe 'search by group name' do
    let_it_be(:group_group_link) { create(:group_group_link, :reporter, shared_with_group: group) }

    it { expect(described_class.search(group.name)).to eq([group_group_link]) }
    it { expect(described_class.search('not-a-group-name')).to be_empty }
  end

  describe 'search by parent group name without `include_parents` option' do
    let_it_be(:group_group_link) { create(:group_group_link, :reporter, shared_with_group: nested_group) }

    it { expect(described_class.search(group.name)).to be_empty }
    it { expect(described_class.search('not-a-group-name')).to be_empty }
  end

  describe 'search by parent group name with `include_parents` option' do
    let_it_be(:group_group_link) { create(:group_group_link, :reporter, shared_with_group: nested_group) }

    it { expect(described_class.search(group.name, include_parents: true)).to eq([group_group_link]) }
    it { expect(described_class.search('not-a-group-name')).to be_empty }
  end
end
