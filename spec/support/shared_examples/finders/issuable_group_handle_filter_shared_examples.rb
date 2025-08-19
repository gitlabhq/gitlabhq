# frozen_string_literal: true

RSpec.shared_examples 'filterable by group handle for' do |issuable_attribute|
  let_it_be(:search_user) { create(:user) }
  let_it_be(:search_group) { create(:group, :private) }
  let_it_be(:group_member_1) { create(:group_member, group: search_group).user }
  let_it_be(:group_member_2) { create(:group_member, group: search_group).user }

  let_it_be(:issuable_1) do
    param = issuable_attribute == :assignees ? [group_member_1] : group_member_1

    send(:create, issuable_factory, *factory_params, **issuable_attributes.merge(issuable_attribute => param))
  end

  let_it_be(:issuable_2) do
    param = issuable_attribute == :assignees ? [group_member_2] : group_member_2

    send(:create, issuable_factory, *factory_params, **issuable_attributes.merge(issuable_attribute => param))
  end

  # Does not match the filter
  let_it_be(:issuable_3) { send(:create, issuable_factory, *factory_params, **issuable_attributes) }

  let(:finder_params) do
    params = search_params

    if issuable_attribute == :author
      params[:author_username] = search_group.to_reference
    elsif issuable_attribute == :assignees || issuable_attribute == :assignee
      params[:assignee_username] = search_group.to_reference
    end

    params[:scope] = 'all'

    params
  end

  subject(:filtered_issuables) { described_class.new(search_user, finder_params).execute }

  before do
    issuable_parent.add_developer(search_user)
  end

  context 'when search user can read group' do
    before_all do
      search_group.add_developer(search_user)
    end

    it 'returns issues authored by group direct members' do
      expect(filtered_issuables).to contain_exactly(issuable_1, issuable_2)
    end

    context 'when group has more members than allowed' do
      before do
        stub_const("Issuables::GroupMembersFilterable::MAX_GROUP_MEMBERS_COUNT", 1)
      end

      it { expect { subject }.to raise_error(Issuables::GroupMembersFilterable::TooManyGroupMembersError) }
    end

    context 'when group has too many assigned issues' do
      before do
        stub_const("Issuables::GroupMembersFilterable::MAX_ASSIGNED_ISSUES_COUNT", 1)
        create(:issue_assignee, user_id: group_member_1.id)
        create(:issue_assignee, user_id: group_member_1.id)
      end

      it { expect { subject }.to raise_error(Issuables::GroupMembersFilterable::TooManyAssignedIssuesError) }
    end
  end

  context 'when search user cannot read group' do
    it 'does not apply filter' do
      expect(filtered_issuables).to be_empty
    end
  end
end
