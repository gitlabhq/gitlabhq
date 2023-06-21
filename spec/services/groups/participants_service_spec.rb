# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ParticipantsService, feature_category: :groups_and_projects do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:subproject) { create(:project, group: subgroup) }

    subject(:service_result) { described_class.new(group, user).execute(nil) }

    before do
      parent_group.add_developer(create(:user))
      subgroup.add_developer(create(:user))
      subproject.add_developer(create(:user))

      stub_feature_flags(disable_all_mention: false)
    end

    it 'includes `All Group Members`' do
      expect(service_result).to include(a_hash_including({ username: "all", name: "All Group Members" }))
    end

    it 'returns all members in parent groups, sub-groups, and sub-projects' do
      expected_users = (group.self_and_hierarchy.flat_map(&:users) + subproject.users)
        .map { |user| user_to_autocompletable(user) }

      expect(expected_users.count).to eq(3)
      expect(service_result).to include(*expected_users)
    end

    context 'when `disable_all_mention` FF is enabled' do
      before do
        stub_feature_flags(disable_all_mention: true)
      end

      it 'does not include `All Group Members`' do
        expect(service_result).not_to include(a_hash_including({ username: "all", name: "All Group Members" }))
      end
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
