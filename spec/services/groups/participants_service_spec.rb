# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ParticipantsService, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent_group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subproject) { create(:project, group: subgroup) }

    let(:service) { described_class.new(group, developer) }

    subject(:service_result) { service.execute(nil) }

    before_all do
      parent_group.add_developer(developer)
    end

    before do
      stub_feature_flags(disable_all_mention: false)
    end

    it 'returns results in correct order' do
      expect(service_result.pluck(:username)).to eq([
        'all', developer.username, parent_group.full_path, subgroup.full_path
      ])
    end

    it 'includes `All Group Members`' do
      group.add_developer(create(:user))

      # These should not be included in the count for the @all entry
      subgroup.add_developer(create(:user))
      subproject.add_developer(create(:user))

      expect(service_result).to include(a_hash_including({ username: "all", name: "All Group Members", count: 1 }))
    end

    context 'when `disable_all_mention` FF is enabled' do
      before do
        stub_feature_flags(disable_all_mention: true)
      end

      it 'does not include `All Group Members`' do
        expect(service_result).not_to include(a_hash_including({ username: "all", name: "All Group Members" }))
      end
    end

    it 'returns all members in parent groups, sub-groups, and sub-projects' do
      parent_group.add_developer(create(:user))
      subgroup.add_developer(create(:user))
      subproject.add_developer(create(:user))

      expected_users = (group.self_and_hierarchy.flat_map(&:users) + subproject.users)
        .map { |user| user_to_autocompletable(user) }

      expect(expected_users.count).to eq(4)
      expect(service_result).to include(*expected_users)
    end

    context 'when shared with a private group' do
      let_it_be(:private_group_member) { create(:user) }
      let_it_be(:private_group) { create(:group, :private, :nested) }

      before_all do
        private_group.add_owner(private_group_member)

        create(:group_group_link, shared_group: parent_group, shared_with_group: private_group)
      end

      subject(:usernames) { service_result.pluck(:username) }

      it { is_expected.to include(private_group_member.username) }
    end
  end

  def user_to_autocompletable(user)
    {
      type: user.class.name,
      username: user.username,
      name: user.name,
      avatar_url: user.avatar_url,
      availability: user&.status&.availability
    }
  end
end
