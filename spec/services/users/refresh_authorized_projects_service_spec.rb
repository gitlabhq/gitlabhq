require 'spec_helper'

describe Users::RefreshAuthorizedProjectsService do
  let(:project) { create(:empty_project) }
  let(:user) { project.namespace.owner }
  let(:service) { described_class.new(user) }

  def create_authorization(project, user, access_level = Gitlab::Access::MASTER)
    ProjectAuthorization.
      create!(project: project, user: user, access_level: access_level)
  end

  describe '#execute' do
    before do
      user.project_authorizations.delete_all
    end

    it 'updates the authorized projects of the user' do
      project2 = create(:empty_project)
      to_remove = create_authorization(project2, user)

      expect(service).to receive(:update_with_lease).
        with([to_remove.id], [[user.id, project.id, Gitlab::Access::MASTER]])

      service.execute
    end

    it 'sets the access level of a project to the highest available level' do
      to_remove = create_authorization(project, user, Gitlab::Access::DEVELOPER)

      expect(service).to receive(:update_with_lease).
        with([to_remove.id], [[user.id, project.id, Gitlab::Access::MASTER]])

      service.execute
    end

    it 'returns a User' do
      expect(service.execute).to be_an_instance_of(User)
    end
  end

  describe '#update_with_lease', :redis do
    it 'refreshes the authorizations using a lease' do
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).
        and_return('foo')

      expect(Gitlab::ExclusiveLease).to receive(:cancel).
        with(an_instance_of(String), 'foo')

      expect(service).to receive(:update_authorizations).with([1], [])

      service.update_with_lease([1])
    end
  end

  describe '#update_authorizations' do
    context 'when there are no rows to add and remove' do
      it 'does not change authorizations' do
        expect(user).not_to receive(:remove_project_authorizations)
        expect(ProjectAuthorization).not_to receive(:insert_authorizations)

        service.update_authorizations([], [])
      end

      context 'when the authorized projects column is not set' do
        before do
          user.update!(authorized_projects_populated: nil)
        end

        it 'populates the authorized projects column' do
          service.update_authorizations([], [])

          expect(user.authorized_projects_populated).to eq true
        end
      end

      context 'when the authorized projects column is set' do
        before do
          user.update!(authorized_projects_populated: true)
        end

        it 'does nothing' do
          expect(user).not_to receive(:set_authorized_projects_column)

          service.update_authorizations([], [])
        end
      end
    end

    it 'removes authorizations that should be removed' do
      authorization = create_authorization(project, user)

      service.update_authorizations([authorization.id])

      expect(user.project_authorizations).to be_empty
    end

    it 'inserts authorizations that should be added' do
      service.update_authorizations([], [[user.id, project.id, Gitlab::Access::MASTER]])

      authorizations = user.project_authorizations

      expect(authorizations.length).to eq(1)
      expect(authorizations[0].user_id).to eq(user.id)
      expect(authorizations[0].project_id).to eq(project.id)
      expect(authorizations[0].access_level).to eq(Gitlab::Access::MASTER)
    end

    it 'populates the authorized projects column' do
      # make sure we start with a nil value no matter what the default in the
      # factory may be.
      user.update!(authorized_projects_populated: nil)

      service.update_authorizations([], [[user.id, project.id, Gitlab::Access::MASTER]])

      expect(user.authorized_projects_populated).to eq(true)
    end
  end

  describe '#fresh_access_levels_per_project' do
    let(:hash) { service.fresh_access_levels_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to eq([project.id])
    end

    it 'sets the values to the access levels' do
      expect(hash.values).to eq([Gitlab::Access::MASTER])
    end
  end

  describe '#current_authorizations_per_project' do
    before { create_authorization(project, user) }

    let(:hash) { service.current_authorizations_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to eq([project.id])
    end

    it 'sets the values to the project authorization rows' do
      expect(hash.values).to eq([ProjectAuthorization.first])
    end
  end

  describe '#current_authorizations' do
    context 'without authorizations' do
      it 'returns an empty list' do
        expect(service.current_authorizations.empty?).to eq(true)
      end
    end

    context 'with an authorization' do
      before { create_authorization(project, user) }

      let(:row) { service.current_authorizations.take }

      it 'returns the currently authorized projects' do
        expect(service.current_authorizations.length).to eq(1)
      end

      it 'includes the row ID for every row' do
        expect(row.id).to be_a_kind_of(Numeric)
      end

      it 'includes the project ID for every row' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level for every row' do
        expect(row.access_level).to eq(Gitlab::Access::MASTER)
      end
    end
  end

  describe '#fresh_authorizations' do
    it 'returns the new authorized projects' do
      expect(service.fresh_authorizations.length).to eq(1)
    end

    it 'returns the highest access level' do
      project.team.add_guest(user)

      rows = service.fresh_authorizations.to_a

      expect(rows.length).to eq(1)
      expect(rows.first.access_level).to eq(Gitlab::Access::MASTER)
    end

    context 'every returned row' do
      let(:row) { service.fresh_authorizations.take }

      it 'includes the project ID' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level' do
        expect(row.access_level).to eq(Gitlab::Access::MASTER)
      end
    end
  end
end
