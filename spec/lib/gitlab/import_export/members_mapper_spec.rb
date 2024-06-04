# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::MembersMapper do
  describe 'map members' do
    shared_examples 'imports exported members' do
      let(:user) { create(:admin) }
      let(:user2) { create(:user) }
      let(:exported_user_id) { 99 }
      let(:exported_members) do
        [{
           "id" => 2,
           "access_level" => 40,
           "source_id" => 14,
           "source_type" => source_type,
           "notification_level" => 3,
           "created_at" => "2016-03-11T10:21:44.822Z",
           "updated_at" => "2016-03-11T10:21:44.822Z",
           "created_by_id" => 1,
           "invite_email" => nil,
           "invite_token" => nil,
           "invite_accepted_at" => nil,
           "user" =>
             {
               "id" => exported_user_id,
               "public_email" => user2.email,
               "username" => 'test'
             },
           "user_id" => 19
         },
         {
           "id" => 3,
           "access_level" => 40,
           "source_id" => 14,
           "source_type" => source_type,
           "user_id" => nil,
           "notification_level" => 3,
           "created_at" => "2016-03-11T10:21:44.822Z",
           "updated_at" => "2016-03-11T10:21:44.822Z",
           "created_by_id" => 2,
           "invite_email" => 'invite@test.com',
           "invite_token" => 'token',
           "invite_accepted_at" => nil
         },
         {
           "id" => 3,
           "access_level" => 40,
           "source_id" => 14,
           "source_type" => source_type,
           "user_id" => nil,
           "notification_level" => 3,
           "created_at" => "2016-03-11T10:21:44.822Z",
           "updated_at" => "2016-03-11T10:21:44.822Z",
           "created_by_id" => nil,
           "invite_email" => 'invite2@test.com',
           "invite_token" => 'token',
           "invite_accepted_at" => nil
         }]
      end

      let(:members_mapper) do
        described_class.new(
          exported_members: exported_members, user: user, importable: importable)
      end

      it 'includes the exported user ID in the map' do
        expect(members_mapper.map.keys).to include(exported_user_id)
      end

      it 'maps a member' do
        expect(members_mapper.map[exported_user_id]).to eq(user2.id)
      end

      it 'defaults to importer member if it does not exist' do
        expect(members_mapper.map[-1]).to eq(user.id)
      end

      it 'has invited members with no user' do
        members_mapper.map

        expect(member_class.find_by_invite_email('invite@test.com')).not_to be_nil
      end

      it 'maps created_by_id to user on new instance' do
        expect(member_class)
          .to receive(:create)
            .once
            .with(hash_including('user_id' => user2.id, 'created_by_id' => nil))
            .and_call_original
        expect(member_class)
          .to receive(:create)
            .once
            .with(hash_including('invite_email' => 'invite@test.com', 'created_by_id' => nil))
            .and_call_original
        expect(member_class)
          .to receive(:create)
            .once
            .with(hash_including('invite_email' => 'invite2@test.com', 'created_by_id' => nil))
            .and_call_original

        members_mapper.map
      end

      it 'replaced user_id with user_id from new instance' do
        expect(member_class)
          .to receive(:create)
            .once
            .with(hash_including('user_id' => user2.id))
            .and_call_original
        expect(member_class)
          .to receive(:create)
            .twice
            .with(hash_excluding('user_id'))
            .and_call_original

        members_mapper.map
      end

      context 'logging' do
        let(:logger) { ::Import::Framework::Logger.build }

        before do
          allow(logger).to receive(:info)
          allow(members_mapper).to receive(:logger).and_return(logger)
        end

        it 'logs member addition' do
          expected_log_params = ->(user_id) do
            {
              user_id: user_id,
              root_namespace_id: importable.root_ancestor.id,
              importable_type: importable.class.to_s,
              importable_id: importable.id,
              access_level: exported_members.first['access_level'],
              message: '[Project/Group Import] Added new member'
            }
          end

          expect(logger).to receive(:info).with(hash_including(expected_log_params.call(user2.id))).once
          expect(logger).to receive(:info).with(hash_including(expected_log_params.call(nil))).twice

          members_mapper.map
        end

        context 'when exporter member is invalid' do
          let(:exported_members) do
            [
              {
                "id" => 2,
                "access_level" => -5, # invalid access level
                "source_id" => 14,
                "source_type" => source_type,
                "notification_level" => 3,
                "created_at" => "2016-03-11T10:21:44.822Z",
                "updated_at" => "2016-03-11T10:21:44.822Z",
                "created_by_id" => nil,
                "invite_email" => nil,
                "invite_token" => nil,
                "invite_accepted_at" => nil,
                "user" =>
                  {
                    "id" => exported_user_id,
                    "public_email" => user2.email,
                    "username" => 'test'
                  },
                "user_id" => 19
              }
            ]
          end

          it 'logs member addition failure' do
            expect(logger).to receive(:info).with(hash_including(message: a_string_including('Access level is not included in the list'))).once

            members_mapper.map
          end
        end
      end

      context 'user is not an admin' do
        let(:user) { create(:user) }

        it 'does not map a member' do
          expect(members_mapper.map[exported_user_id]).to eq(user.id)
        end

        it 'defaults to importer member if it does not exist' do
          expect(members_mapper.map[-1]).to eq(user.id)
        end
      end

      context 'chooses the one with an email' do
        let(:user3) { create(:user, username: 'test') }

        it 'maps the member that has a matching email' do
          expect(members_mapper.map[exported_user_id]).to eq(user2.id)
        end
      end

      context 'when user has email exported' do
        let(:exported_members) do
          [
            {
              "id" => 2,
              "access_level" => 40,
              "source_id" => 14,
              "source_type" => source_type,
              "notification_level" => 3,
              "created_at" => "2016-03-11T10:21:44.822Z",
              "updated_at" => "2016-03-11T10:21:44.822Z",
              "created_by_id" => nil,
              "invite_email" => nil,
              "invite_token" => nil,
              "invite_accepted_at" => nil,
              "user" =>
                {
                  "id" => exported_user_id,
                  "email" => user2.email,
                  "username" => 'test'
                },
              "user_id" => 19
            }
          ]
        end

        it 'maps a member' do
          expect(members_mapper.map[exported_user_id]).to eq(user2.id)
        end
      end
    end

    context 'when importable is Project' do
      include_examples 'imports exported members' do
        let(:source_type) { 'Project' }
        let(:member_class) { ProjectMember }
        let(:importable) { create(:project, :public, name: 'searchable_project') }

        it 'adds users to project members' do
          members_mapper.map

          expect(importable.reload.members.map(&:user)).to include(user, user2)
        end

        it 'maps an owner as a maintainer' do
          exported_members.first['access_level'] = ProjectMember::OWNER

          expect(members_mapper.map[exported_user_id]).to eq(user2.id)
          expect(member_class.find_by_user_id(user2.id).access_level).to eq(ProjectMember::MAINTAINER)
        end

        context 'importer same as group member' do
          let(:user2) { create(:admin) }
          let(:group) { create(:group) }
          let(:importable) { create(:project, :public, name: 'searchable_project', namespace: group) }
          let(:members_mapper) do
            described_class.new(
              exported_members: exported_members, user: user2, importable: importable)
          end

          before do
            group.add_members([user, user2], GroupMember::DEVELOPER)
          end

          it 'maps the project member' do
            expect(members_mapper.map[exported_user_id]).to eq(user2.id)
          end

          it 'maps the project member if it already exists' do
            importable.add_maintainer(user2)

            expect(members_mapper.map[exported_user_id]).to eq(user2.id)
          end
        end

        context 'importing group members' do
          let(:group) { create(:group) }
          let(:importable) { create(:project, namespace: group) }
          let(:members_mapper) do
            described_class.new(
              exported_members: exported_members, user: user, importable: importable)
          end

          before do
            group.add_members([user, user2], GroupMember::DEVELOPER)
          end

          it 'maps the importer' do
            expect(members_mapper.map[-1]).to eq(user.id)
          end

          it 'maps the group member' do
            expect(members_mapper.map[exported_user_id]).to eq(user2.id)
          end
        end

        context 'when importer mapping fails' do
          let(:exception_message) { 'Something went wrong' }

          it 'includes importer specific error message' do
            expect(member_class).to receive(:create!).and_raise(StandardError.new(exception_message))

            expect { members_mapper.map }.to raise_error(StandardError, "Error adding importer user to Project members. #{exception_message}")
          end
        end
      end
    end

    context 'when importer is not an admin' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:members_mapper) do
        described_class.new(
          exported_members: [], user: user, importable: importable)
      end

      shared_examples_for 'it fetches the access level from parent group' do
        before do
          group.add_members([user], group_access_level)
        end

        it "and resolves it correctly" do
          members_mapper.map
          expect(member_class.find_by_user_id(user.id).access_level).to eq(resolved_access_level)
        end
      end

      context 'and the imported project is part of a group' do
        let(:importable) { create(:project, namespace: group) }
        let(:member_class) { ProjectMember }

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::DEVELOPER }
          let(:resolved_access_level) { ProjectMember::DEVELOPER }
        end

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::MAINTAINER }
          let(:resolved_access_level) { ProjectMember::MAINTAINER }
        end

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::OWNER }
          let(:resolved_access_level) { ProjectMember::MAINTAINER }
        end
      end

      context 'and the imported group is part of another group' do
        let(:importable) { create(:group, parent: group) }
        let(:member_class) { GroupMember }

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::DEVELOPER }
          let(:resolved_access_level) { GroupMember::DEVELOPER }
        end

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::MAINTAINER }
          let(:resolved_access_level) { GroupMember::MAINTAINER }
        end

        it_behaves_like 'it fetches the access level from parent group' do
          let(:group_access_level) { GroupMember::OWNER }
          let(:resolved_access_level) { GroupMember::OWNER }
        end
      end
    end

    context 'when importable is Group' do
      include_examples 'imports exported members' do
        let(:source_type) { 'Namespace' }
        let(:member_class) { GroupMember }
        let(:importable) { create(:group) }

        it 'does not lower owner access level' do
          exported_members.first['access_level'] = member_class::OWNER

          expect(members_mapper.map[exported_user_id]).to eq(user2.id)
          expect(member_class.find_by_user_id(user2.id).access_level).to eq(member_class::OWNER)
        end
      end
    end
  end
end
