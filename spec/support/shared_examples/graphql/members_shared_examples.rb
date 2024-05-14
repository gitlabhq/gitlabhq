# frozen_string_literal: true

RSpec.shared_examples 'a working membership object query' do |model_option|
  let_it_be(:member_source) { member.source }
  let_it_be(:member_source_type) { member_source.class.to_s.downcase }

  it 'contains edge to expected project' do
    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, member_source_type, 'id')
    ).to eq(member.send(member_source_type).to_global_id.to_s)
  end

  it 'contains correct access level' do
    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, 'accessLevel', 'integerValue')
    ).to eq(30)

    expect(
      graphql_data.dig('user', "#{member_source_type}Memberships", 'nodes', 0, 'accessLevel', 'stringValue')
    ).to eq('DEVELOPER')
  end
end

RSpec.shared_examples 'querying members with a group' do
  let_it_be(:root_group) { create(:group, :private) }
  let_it_be(:group_1)    { create(:group, :private, parent: root_group, name: 'Main Group') }
  let_it_be(:group_2)    { create(:group, :private, parent: root_group) }

  let_it_be(:user_1) { create(:user, name: 'test user') }
  let_it_be(:user_2) { create(:user, name: 'test user 2') }
  let_it_be(:user_3) { create(:user, name: 'another user 1') }
  let_it_be(:user_4) { create(:user, name: 'another user 2') }

  let_it_be(:root_group_member) { create(:group_member, user: user_4, group: root_group) }
  let_it_be(:group_1_member)    { create(:group_member, user: user_2, group: group_1) }
  let_it_be(:group_2_member)    { create(:group_member, user: user_3, group: group_2) }

  let(:args) { {} }
  let(:base_args) { { relations: described_class.arguments['relations'].default_value } }

  subject(:group_members) do
    resolve(
      described_class, obj: resource, args: base_args.merge(args),
      ctx: { current_user: user_4 }, arg_style: :internal
    )
  end

  describe '#resolve' do
    before do
      group_1.add_maintainer(user_4)
    end

    it 'finds all resource members' do
      expect(group_members).to contain_exactly(resource_member, group_1_member, root_group_member)
    end

    context 'with sort options' do
      let(:args) { { sort: 'name_asc' } }

      it 'searches users by user name' do
        # the order is important here
        expect(group_members.items).to eq([root_group_member, resource_member, group_1_member])
      end
    end

    context 'with search' do
      context 'when the search term matches a user' do
        let(:args) { { search: 'test' } }

        it 'searches users by user name' do
          expect(group_members).to contain_exactly(resource_member, group_1_member)
        end
      end

      context 'when the search term does not match any user' do
        let(:args) { { search: 'nothing' } }

        it 'is empty' do
          expect(group_members).to be_empty
        end
      end
    end

    context 'when user can not see resource members' do
      let_it_be(:other_user) { create(:user) }

      subject(:group_members) do
        resolve(
          described_class, obj: resource, args: base_args.merge(args),
          ctx: { current_user: other_user }, arg_style: :internal
        )
      end

      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          group_members
        end
      end
    end
  end
end
