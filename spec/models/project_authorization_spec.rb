# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorization do
  let_it_be(:user) { create(:user) }
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }

  describe '.insert_authorizations' do
    it 'inserts the authorizations' do
      described_class
        .insert_authorizations([[user.id, project1.id, Gitlab::Access::MAINTAINER]])

      expect(user.project_authorizations.count).to eq(1)
    end

    it 'inserts rows in batches' do
      described_class.insert_authorizations([
        [user.id, project1.id, Gitlab::Access::MAINTAINER],
        [user.id, project2.id, Gitlab::Access::MAINTAINER]
      ], 1)

      expect(user.project_authorizations.count).to eq(2)
    end

    it 'skips duplicates and inserts the remaining rows without error' do
      create(:project_authorization, user: user, project: project1, access_level: Gitlab::Access::MAINTAINER)

      rows = [
        [user.id, project1.id, Gitlab::Access::MAINTAINER],
        [user.id, project2.id, Gitlab::Access::MAINTAINER],
        [user.id, project3.id, Gitlab::Access::MAINTAINER]
      ]

      described_class.insert_authorizations(rows)

      expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(rows)
    end
  end
end
