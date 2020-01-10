# frozen_string_literal: true

require 'spec_helper'

describe Projects::ParticipantsService do
  describe '#groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let(:service) { described_class.new(project, user) }

    it 'avoids N+1 queries' do
      group_1 = create(:group)
      group_1.add_owner(user)

      service.groups # Run general application warmup queries
      control_count = ActiveRecord::QueryRecorder.new { service.groups }.count

      group_2 = create(:group)
      group_2.add_owner(user)

      expect { service.groups }.not_to exceed_query_limit(control_count)
    end

    it 'returns correct user counts for groups' do
      group_1 = create(:group)
      group_1.add_owner(user)
      group_1.add_owner(create(:user))

      group_2 = create(:group)
      group_2.add_owner(user)
      create(:group_member, :access_request, group: group_2, user: create(:user))

      expect(service.groups).to contain_exactly(
        a_hash_including(name: group_1.full_name, count: 2),
        a_hash_including(name: group_2.full_name, count: 1)
      )
    end

    describe 'avatar_url' do
      let(:group) { create(:group, avatar: fixture_file_upload('spec/fixtures/dk.png')) }

      before do
        group.add_owner(user)
      end

      it 'returns an url for the avatar' do
        expect(service.groups.size).to eq 1
        expect(service.groups.first[:avatar_url]).to eq("/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end

      it 'returns an url for the avatar with relative url' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        expect(service.groups.size).to eq 1
        expect(service.groups.first[:avatar_url]).to eq("/gitlab/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end
    end
  end

  describe '#project_members' do
    subject(:usernames) { service.project_members.map { |member| member[:username] } }

    context 'when there is a project in group namespace' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:public_project) { create(:project, :public, namespace: public_group)}

      let_it_be(:public_group_owner) { create(:user) }

      let(:service) { described_class.new(public_project, create(:user)) }

      before do
        public_group.add_owner(public_group_owner)
      end

      it 'returns members of a group' do
        expect(usernames).to include(public_group_owner.username)
      end
    end

    context 'when there is a private group and a public project' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:private_group) { create(:group, :private, :nested) }
      let_it_be(:public_project) { create(:project, :public, namespace: public_group)}

      let_it_be(:project_issue) { create(:issue, project: public_project)}

      let_it_be(:public_group_owner) { create(:user) }
      let_it_be(:private_group_member) { create(:user) }
      let_it_be(:public_project_maintainer) { create(:user) }
      let_it_be(:private_group_owner) { create(:user) }

      let_it_be(:group_ancestor_owner) { create(:user) }

      before(:context) do
        public_group.add_owner public_group_owner
        private_group.add_developer private_group_member
        public_project.add_maintainer public_project_maintainer

        private_group.add_owner private_group_owner
        private_group.parent.add_owner group_ancestor_owner
      end

      context 'when the private group is invited to the public project' do
        before(:context) do
          create(:project_group_link, group: private_group, project: public_project)
        end

        context 'when a user who is outside the public project and the private group is signed in' do
          let(:service) { described_class.new(public_project, create(:user)) }

          it 'does not return the private group' do
            expect(usernames).not_to include(private_group.name)
          end

          it 'does not return private group members' do
            expect(usernames).not_to include(private_group_member.username)
          end

          it 'returns the project maintainer' do
            expect(usernames).to include(public_project_maintainer.username)
          end

          it 'returns project members from an invited public group' do
            invited_public_group = create(:group, :public)
            invited_public_group.add_owner create(:user)

            create(:project_group_link, group: invited_public_group, project: public_project)

            expect(usernames).to include(invited_public_group.users.first.username)
          end

          it 'does not return ancestors of the private group' do
            expect(usernames).not_to include(group_ancestor_owner.username)
          end
        end

        context 'when private group owner is signed in' do
          let(:service) { described_class.new(public_project, private_group_owner) }

          it 'returns private group members' do
            expect(usernames).to include(private_group_member.username)
          end

          it 'returns ancestors of the the private group' do
            expect(usernames).to include(group_ancestor_owner.username)
          end
        end

        context 'when the namespace owner of the public project is signed in' do
          let(:service) { described_class.new(public_project, public_group_owner) }

          it 'returns private group members' do
            expect(usernames).to include(private_group_member.username)
          end

          it 'does not return members of the ancestral groups of the private group' do
            expect(usernames).to include(group_ancestor_owner.username)
          end
        end
      end
    end
  end
end
