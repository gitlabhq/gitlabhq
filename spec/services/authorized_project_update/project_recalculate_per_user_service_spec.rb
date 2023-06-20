# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculatePerUserService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }

  subject(:execute) { described_class.new(project, user).execute }

  it 'returns success' do
    expect(execute.success?).to eq(true)
  end

  context 'when there are no changes to be made' do
    it 'does not change authorizations' do
      expect { execute }.not_to(change { ProjectAuthorization.count })
    end
  end

  context 'when there are changes to be made' do
    context 'when addition is required' do
      before do
        project.add_developer(user)
        project.add_developer(another_user)
        project.project_authorizations.where(user: [user, another_user]).delete_all
      end

      it 'adds a new authorization record for the specific user' do
        expect { execute }.to(
          change { project.project_authorizations.where(user: user).count }
          .from(0).to(1)
        )
      end

      it 'does not add a new authorization record for the other user' do
        expect { execute }.not_to(
          change { project.project_authorizations.where(user: another_user).count }
        )
      end

      it 'adds a new authorization record with the correct access level for the specific user' do
        execute

        project_authorization = project.project_authorizations.where(
          user: user,
          access_level: Gitlab::Access::DEVELOPER
        )

        expect(project_authorization).to exist
      end
    end

    context 'when removal is required' do
      before do
        create(:project_authorization, user: user, project: project)
        create(:project_authorization, user: another_user, project: project)
      end

      it 'removes the authorization record for the specific user' do
        expect { execute }.to(
          change { project.project_authorizations.where(user: user).count }
          .from(1).to(0)
        )
      end

      it 'does not remove the authorization record for the other user' do
        expect { execute }.not_to(
          change { project.project_authorizations.where(user: another_user).count }
        )
      end
    end

    context 'when an update in access level is required' do
      before do
        project.add_developer(user)
        project.add_developer(another_user)
        project.project_authorizations.where(user: [user, another_user]).delete_all
        create(:project_authorization, project: project, user: user, access_level: Gitlab::Access::GUEST)
        create(:project_authorization, project: project, user: another_user, access_level: Gitlab::Access::GUEST)
      end

      it 'updates the authorization of the specific user to the correct access level' do
        expect { execute }.to(
          change { project.project_authorizations.find_by(user: user).access_level }
            .from(Gitlab::Access::GUEST).to(Gitlab::Access::DEVELOPER)
        )
      end

      it 'does not update the authorization of the other user to the correct access level' do
        expect { execute }.not_to(
          change { project.project_authorizations.find_by(user: another_user).access_level }
            .from(Gitlab::Access::GUEST)
        )
      end
    end
  end
end
