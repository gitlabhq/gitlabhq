# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::FindRecordsDueForRefreshService, feature_category: :groups_and_projects do
  # We're using let! here so that any expectations for the service class are not
  # triggered twice.
  let!(:project) { create(:project) }

  let(:user) { project.namespace.owner }
  let(:service) { described_class.new(user) }

  describe '#execute' do
    context 'callbacks' do
      let(:callback) { double('callback') }

      context 'incorrect_auth_found_callback callback' do
        let(:user) { create(:user) }
        let(:service) do
          described_class.new(user, incorrect_auth_found_callback: callback)
        end

        it 'is called' do
          access_level = Gitlab::Access::DEVELOPER
          create(:project_authorization, user: user, project: project, access_level: access_level)

          expect(callback).to receive(:call).with(project.id, access_level).once

          service.execute
        end
      end

      context 'missing_auth_found_callback callback' do
        let(:service) do
          described_class.new(user, missing_auth_found_callback: callback)
        end

        it 'is called' do
          ProjectAuthorization.delete_all

          expect(callback).to receive(:call).with(project.id, Gitlab::Access::OWNER).once

          service.execute
        end
      end
    end

    context 'finding project authorizations due for refresh' do
      context 'when there are changes to be made' do
        before do
          user.project_authorizations.delete_all
        end

        it 'finds projects authorizations that needs to be refreshed' do
          project2 = create(:project)
          user.project_authorizations
            .create!(project: project2, access_level: Gitlab::Access::MAINTAINER)

          to_be_removed = [project2.id]
          to_be_added = [
            { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::OWNER }
          ]

          expect(service.execute).to eq([to_be_removed, to_be_added])
        end

        it 'finds entries with wrong access levels' do
          user.project_authorizations
            .create!(project: project, access_level: Gitlab::Access::DEVELOPER)

          to_be_removed = [project.id]
          to_be_added = [
            { user_id: user.id, project_id: project.id, access_level: Gitlab::Access::OWNER }
          ]

          expect(service.execute).to eq([to_be_removed, to_be_added])
        end
      end

      context 'when there are no changes to be made' do
        it 'returns empty arrays' do
          expect(service.execute).to eq([[], []])
        end
      end
    end
  end

  describe '#needs_refresh?' do
    subject { service.needs_refresh? }

    context 'when there are records due for either removal or addition' do
      context 'when there are both removals and additions to be made' do
        before do
          user.project_authorizations.delete_all
          create(:project_authorization, user: user)
        end

        it { is_expected.to eq(true) }
      end

      context 'when there are no removals, but there are additions to be made' do
        before do
          user.project_authorizations.delete_all
        end

        it { is_expected.to eq(true) }
      end

      context 'when there are no additions, but there are removals to be made' do
        before do
          create(:project_authorization, user: user)
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when there are no additions or removals to be made' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#fresh_access_levels_per_project' do
    let(:hash) { service.fresh_access_levels_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to match_array([project.id])
    end

    it 'sets the values to the access levels' do
      expect(hash.values).to match_array([Gitlab::Access::OWNER])
    end

    context 'personal projects' do
      it 'includes the project with the right access level' do
        expect(hash[project.id]).to eq(Gitlab::Access::OWNER)
      end
    end

    context 'projects the user is a member of' do
      let!(:other_project) { create(:project) }

      before do
        other_project.team.add_reporter(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::REPORTER)
      end
    end

    context 'projects of groups the user is a member of' do
      let(:group) { create(:group) }
      let!(:other_project) { create(:project, group: group) }

      before do
        group.add_owner(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::OWNER)
      end
    end

    context 'projects of subgroups of groups the user is a member of' do
      let(:group) { create(:group) }
      let(:nested_group) { create(:group, parent: group) }
      let!(:other_project) { create(:project, group: nested_group) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::MAINTAINER)
      end
    end

    context 'projects shared with groups the user is a member of' do
      let(:group) { create(:group) }
      let(:other_project) { create(:project) }
      let!(:project_group_link) { create(:project_group_link, project: other_project, group: group, group_access: Gitlab::Access::GUEST) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::GUEST)
      end
    end

    context 'projects shared with subgroups of groups the user is a member of' do
      let(:group) { create(:group) }
      let(:nested_group) { create(:group, parent: group) }
      let(:other_project) { create(:project) }
      let!(:project_group_link) { create(:project_group_link, project: other_project, group: nested_group, group_access: Gitlab::Access::DEVELOPER) }

      before do
        group.add_maintainer(user)
      end

      it 'includes the project with the right access level' do
        expect(hash[other_project.id]).to eq(Gitlab::Access::DEVELOPER)
      end
    end
  end

  describe '#current_authorizations_per_project' do
    let(:hash) { service.current_authorizations_per_project }

    it 'returns a Hash' do
      expect(hash).to be_an_instance_of(Hash)
    end

    it 'sets the keys to the project IDs' do
      expect(hash.keys).to eq([project.id])
    end

    it 'sets the values to the project authorization rows' do
      expect(hash.values.length).to eq(1)

      value = hash.values[0]

      expect(value.project_id).to eq(project.id)
      expect(value.access_level).to eq(Gitlab::Access::OWNER)
    end
  end

  describe '#current_authorizations' do
    context 'without authorizations' do
      it 'returns an empty list' do
        user.project_authorizations.delete_all

        expect(service.current_authorizations.empty?).to eq(true)
      end
    end

    context 'with an authorization' do
      let(:row) { service.current_authorizations.take }

      it 'returns the currently authorized projects' do
        expect(service.current_authorizations.length).to eq(1)
      end

      it 'includes the project ID for every row' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level for every row' do
        expect(row.access_level).to eq(Gitlab::Access::OWNER)
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
      expect(rows.first.access_level).to eq(Gitlab::Access::OWNER)
    end

    context 'every returned row' do
      let(:row) { service.fresh_authorizations.take }

      it 'includes the project ID' do
        expect(row.project_id).to eq(project.id)
      end

      it 'includes the access level' do
        expect(row.access_level).to eq(Gitlab::Access::OWNER)
      end
    end
  end
end
