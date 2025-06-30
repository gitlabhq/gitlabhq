# frozen_string_literal: true

RSpec.shared_examples 'filterable by group handle' do
  let_it_be(:search_user) { create(:user) }
  let_it_be(:search_group) { create(:group, :private) }
  let_it_be(:group_member_1) { create(:group_member, group: search_group).user }
  let_it_be(:group_member_2) { create(:group_member, group: search_group).user }

  let_it_be(:issuable_1) do
    send(:create, issuable_factory, *factory_params, **issuable_attributes.merge(author: group_member_1))
  end

  let_it_be(:issuable_2) do
    send(:create, issuable_factory, *factory_params, **issuable_attributes.merge(author: group_member_2))
  end

  # Not authored by a group member
  let_it_be(:issuable_3) { send(:create, issuable_factory, *factory_params, **issuable_attributes) }

  let(:finder_params) do
    params = search_params
    params[:author_username] = search_group.to_reference
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
        stub_const("Issuables::AuthorFilter::MAX_GROUP_MEMBERS_COUNT", 1)
      end

      it { expect { subject }.to raise_error(Issuables::AuthorFilter::TooManyGroupMembersError) }
    end
  end

  context 'when search user cannot read group' do
    it 'does not apply filter' do
      expect(filtered_issuables).to be_empty
    end
  end
end
