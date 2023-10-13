# frozen_string_literal: true

require 'spec_helper'

# Creation is necessary due to relations and the need to check in the presenter
#
# rubocop:disable RSpec/FactoryBot/AvoidCreate
RSpec.describe MemberPresenter, feature_category: :groups_and_projects do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root_group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:root_member) { create(:group_member, :reporter, group: root_group, user: user) }
  let_it_be(:subgroup_member) { create(:group_member, :reporter, group: subgroup, user: user) }

  let(:presenter) { described_class.new(root_member) }

  describe '#last_owner?' do
    it 'raises `NotImplementedError`' do
      expect { presenter.last_owner? }.to raise_error(NotImplementedError)
    end
  end

  describe '#valid_level_roles' do
    it 'does not return levels lower than user highest membership in the hierarchy' do
      expect(described_class.new(subgroup_member).valid_level_roles).to eq(
        'Reporter' => Gitlab::Access::REPORTER,
        'Developer' => Gitlab::Access::DEVELOPER,
        'Maintainer' => Gitlab::Access::MAINTAINER,
        'Owner' => Gitlab::Access::OWNER
      )
    end

    it 'returns all roles for the root group' do
      expect(described_class.new(root_member).valid_level_roles).to eq(
        'Guest' => Gitlab::Access::GUEST,
        'Reporter' => Gitlab::Access::REPORTER,
        'Developer' => Gitlab::Access::DEVELOPER,
        'Maintainer' => Gitlab::Access::MAINTAINER,
        'Owner' => Gitlab::Access::OWNER
      )
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
