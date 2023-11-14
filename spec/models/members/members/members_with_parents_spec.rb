# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MembersWithParents, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:maintainer) { group.parent.add_maintainer(create(:user)) }
  let_it_be(:developer) { group.add_developer(create(:user)) }
  let_it_be(:pending_maintainer) { create(:group_member, :awaiting, :maintainer, group: group.parent) }
  let_it_be(:pending_developer) { create(:group_member, :awaiting, :developer, group: group) }
  let_it_be(:invited_member) { create(:group_member, :invited, group: group) }
  let_it_be(:inactive_developer) { group.add_developer(create(:user, :deactivated)) }
  let_it_be(:minimal_access) { create(:group_member, :minimal_access, group: group) }

  describe '#all_members' do
    subject(:all_members) { described_class.new(group).all_members }

    it 'returns all members for group and group parents' do
      expect(all_members).to contain_exactly(
        developer,
        maintainer,
        pending_maintainer,
        pending_developer,
        invited_member,
        inactive_developer,
        minimal_access
      )
    end
  end

  describe '#members' do
    let(:arguments) { {} }

    subject(:members) { described_class.new(group).members(**arguments) }

    using Rspec::Parameterized::TableSyntax

    where(:arguments, :expected_members) do
      [
        [
          {},
          lazy { [developer, maintainer, inactive_developer] }
        ],
        [
          # minimal access is Premium, so in FOSS we will not include minimal access member
          { minimal_access: true },
          lazy { [developer, maintainer, inactive_developer] }
        ],
        [
          { active_users: true },
          lazy { [developer, maintainer] }
        ]
      ]
    end

    with_them do
      it 'returns expected members' do
        expect(members).to contain_exactly(*expected_members)
        expect(members).not_to include(*(group.members - expected_members))
      end
    end

    context 'when active_users: true and minimal_access: true' do
      let(:arguments) { { active_users: true, minimal_access: true } }

      it 'raises an error' do
        expect { members }.to raise_error(ArgumentError)
      end
    end

    context 'with group sharing' do
      let_it_be(:shared_with_group) { create(:group) }

      let_it_be(:shared_with_group_maintainer) do
        shared_with_group.add_maintainer(create(:user))
      end

      let_it_be(:shared_with_group_developer) do
        shared_with_group.add_developer(create(:user))
      end

      before do
        create(:group_group_link, shared_group: group, shared_with_group: shared_with_group)
      end

      it 'returns shared with group members' do
        expect(members).to(include(shared_with_group_maintainer))
        expect(members).to(include(shared_with_group_developer))
      end
    end
  end
end
