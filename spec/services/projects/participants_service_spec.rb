# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ParticipantsService, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:noteable) { create(:issue, project: project) }

    let(:params) { {} }

    before_all do
      project.add_developer(user)
    end

    before do
      stub_feature_flags(disable_all_mention: false)
    end

    def run_service
      described_class.new(project, user, params).execute(noteable)
    end

    it 'returns results in correct order' do
      group = create(:group, owners: user)

      expect(run_service.pluck(:username)).to eq([
        noteable.author.username, 'all', user.username, group.full_path
      ])
    end

    it 'includes `All Project and Group Members`' do
      expect(run_service).to include(a_hash_including({ username: "all", name: "All Project and Group Members" }))
    end

    context 'N+1 checks' do
      before do
        run_service # warmup, runs table cache queries and create queries
        BatchLoader::Executor.clear_current
      end

      it 'avoids N+1 UserDetail queries' do
        project.add_developer(create(:user))

        control = ActiveRecord::QueryRecorder.new { run_service.to_a }

        BatchLoader::Executor.clear_current

        project.add_developer(create(:user, status: build(:user_status, availability: :busy)))

        expect { run_service.to_a }.not_to exceed_query_limit(control)
      end

      it 'avoids N+1 groups queries' do
        group_1 = create(:group)
        group_1.add_owner(user)

        control = ActiveRecord::QueryRecorder.new { run_service }

        BatchLoader::Executor.clear_current

        group_2 = create(:group)
        group_2.add_owner(user)

        expect { run_service }.not_to exceed_query_limit(control)
      end
    end

    it 'does not return duplicate author' do
      participants = run_service

      expect(participants.count { |p| p[:username] == noteable.author.username }).to eq 1
    end

    context 'when noteable.participants contains placeholder or import users' do
      let(:placeholder_user) { create(:user, :placeholder) }
      let(:import_user) { create(:user, :import_user) }

      it 'does not return the placeholder and import users' do
        allow(noteable).to receive(:participants).and_return([user, placeholder_user, import_user])

        participant_usernames = run_service.map { |user| user[:username] }

        expect(participant_usernames).not_to include(placeholder_user.username, import_user.username)
        expect(participant_usernames).to include(user.username)
      end
    end

    describe 'group items' do
      subject(:group_items) { run_service.select { |hash| hash[:type].eql?('Group') } }

      describe 'group user counts' do
        let(:group_1) { create(:group) }
        let(:group_2) { create(:group) }

        before do
          group_1.add_owner(user)
          group_1.add_owner(create(:user))

          group_2.add_owner(user)
          create(:group_member, :access_request, group: group_2, user: create(:user))
        end

        it 'returns correct user counts for groups' do
          expect(group_items).to contain_exactly(
            a_hash_including(name: group_1.full_name, count: 2),
            a_hash_including(name: group_2.full_name, count: 1)
          )
        end
      end

      describe 'avatar_url' do
        let(:group) { create(:group, avatar: fixture_file_upload('spec/fixtures/dk.png')) }

        before do
          group.add_owner(user)
        end

        it 'returns an url for the avatar' do
          expect(group_items.size).to eq 1
          expect(group_items.first[:avatar_url]).to eq("/uploads/-/system/group/avatar/#{group.id}/dk.png")
        end

        it 'returns an url for the avatar with relative url' do
          stub_config_setting(relative_url_root: '/gitlab')
          stub_config_setting(url: Settings.send(:build_gitlab_url))

          expect(group_items.size).to eq 1
          expect(group_items.first[:avatar_url]).to eq("/gitlab/uploads/-/system/group/avatar/#{group.id}/dk.png")
        end
      end

      context 'with subgroups' do
        let(:group_1) { create(:group, path: 'bb') }
        let(:group_2) { create(:group, path: 'zz') }
        let(:subgroup) { create(:group, path: 'aa', parent: group_1) }

        before do
          group_1.add_owner(user)
          group_2.add_owner(user)
          subgroup.add_owner(user)
        end

        it 'returns results ordered by full path' do
          expect(group_items.pluck(:username)).to eq([
            group_1.full_path, subgroup.full_path, group_2.full_path
          ])
        end

        context 'when search param is given' do
          let(:params) { { search: 'bb' } }

          it 'only returns matching groups' do
            expect(group_items.pluck(:username)).to eq([
              group_1.full_path, subgroup.full_path
            ])
          end

          context 'when user search already returns enough results' do
            before do
              described_class::SEARCH_LIMIT.times { |i| create(:user, name: "bb#{i}", guest_of: project) }
            end

            it 'does not return any groups' do
              expect(group_items).to be_empty
            end
          end
        end
      end
    end

    context 'when `disable_all_mention` FF is enabled' do
      before do
        stub_feature_flags(disable_all_mention: true)
      end

      it 'does not include `All Project and Group Members`' do
        expect(run_service).not_to include(a_hash_including({ username: "all", name: "All Project and Group Members" }))
      end
    end
  end

  describe '#project_members' do
    subject(:usernames) { service.project_members.map { |member| member[:username] } }

    context 'when there is a project in group namespace' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:public_project, reload: true) { create(:project, :public, namespace: public_group) }

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
      let_it_be(:public_project, reload: true) { create(:project, :public, namespace: public_group) }

      let_it_be(:project_issue) { create(:issue, project: public_project) }

      let_it_be(:public_group_owner) { create(:user) }
      let_it_be(:private_group_member) { create(:user) }
      let_it_be(:public_project_maintainer) { create(:user) }
      let_it_be(:private_group_owner) { create(:user) }

      let_it_be(:group_ancestor_owner) { create(:user) }

      before_all do
        public_group.add_owner public_group_owner
        private_group.add_developer private_group_member
        public_project.add_maintainer public_project_maintainer

        private_group.add_owner private_group_owner
        private_group.parent.add_owner group_ancestor_owner
      end

      context 'when the private group is invited to the public project' do
        before_all do
          create(:project_group_link, group: private_group, project: public_project)
        end

        let(:service) { described_class.new(public_project, create(:user)) }

        it 'does not return the private group' do
          expect(usernames).not_to include(private_group.name)
        end

        it 'returns private group members' do
          expect(usernames).to include(private_group_member.username)
        end

        it 'returns the project maintainer' do
          expect(usernames).to include(public_project_maintainer.username)
        end

        it 'returns project members from an invited public group' do
          invited_public_group = create(:group, :public)
          invited_public_group.add_owner create(:user)

          create(:project_group_link, group: invited_public_group, project: public_project)

          expect(usernames).to include(invited_public_group.group_members.first.user.username)
        end

        it 'returns members of the ancestral groups of the private group' do
          expect(usernames).to include(group_ancestor_owner.username)
        end

        it 'returns invited group members of the private group' do
          invited_group = create(:group, :public)
          create(:group_group_link, shared_group: private_group, shared_with_group: invited_group)

          other_user = create(:user)
          invited_group.add_guest(other_user)

          expect(usernames).to include(other_user.username)
        end
      end
    end

    context 'when search param is given' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:member_1) { create(:user, name: 'John Doe', guest_of: project) }
      let_it_be(:member_2) { create(:user, name: 'Jane Doe ', guest_of: project) }

      let(:service) { described_class.new(project, create(:user), search: 'johnd') }

      it 'only returns matching members' do
        expect(usernames).to eq([member_1.username])
      end
    end
  end
end
