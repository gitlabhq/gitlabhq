# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculateService, '#execute' do
  let_it_be(:project) { create(:project) }

  subject(:execute) { described_class.new(project).execute }

  it 'returns success' do
    expect(execute.success?).to eq(true)
  end

  context 'when there are no changes to be made' do
    it 'does not change authorizations' do
      expect { execute }.not_to(change { ProjectAuthorization.count })
    end
  end

  context 'when there are changes to be made' do
    let(:user) { create(:user) }

    context 'when addition is required' do
      before do
        project.add_developer(user)
        project.project_authorizations.where(user: user).delete_all
      end

      it 'adds a new authorization record' do
        expect { execute }.to(
          change { project.project_authorizations.where(user: user).count }
          .from(0).to(1)
        )
      end

      it 'adds a new authorization record with the correct access level' do
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
      end

      it 'removes the authorization record' do
        expect { execute }.to(
          change { project.project_authorizations.where(user: user).count }
          .from(1).to(0)
        )
      end
    end

    context 'when an update in access level is required' do
      before do
        project.add_developer(user)
        project.project_authorizations.where(user: user).delete_all
        create(:project_authorization, project: project, user: user, access_level: Gitlab::Access::GUEST)
      end

      it 'updates the authorization of the user to the correct access level' do
        expect { execute }.to(
          change { project.project_authorizations.find_by(user: user).access_level }
            .from(Gitlab::Access::GUEST).to(Gitlab::Access::DEVELOPER)
        )
      end
    end
  end
end
