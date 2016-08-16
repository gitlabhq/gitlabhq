require 'spec_helper'

describe Gitlab::ImportExport::MembersMapper, services: true do
  describe 'map members' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, name: 'searchable_project') }
    let(:user2) { create(:user) }
    let(:exported_user_id) { 99 }
    let(:exported_members) do
      [{
         "id" => 2,
         "access_level" => 40,
         "source_id" => 14,
         "source_type" => "Project",
         "user_id" => 19,
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
             "username" => user2.username
           }
       },
       {
         "id" => 3,
         "access_level" => 40,
         "source_id" => 14,
         "source_type" => "Project",
         "user_id" => nil,
         "notification_level" => 3,
         "created_at" => "2016-03-11T10:21:44.822Z",
         "updated_at" => "2016-03-11T10:21:44.822Z",
         "created_by_id" => 1,
         "invite_email" => 'invite@test.com',
         "invite_token" => 'token',
         "invite_accepted_at" => nil
       }]
    end

    let(:members_mapper) do
      described_class.new(
        exported_members: exported_members, user: user, project: project)
    end

    it 'maps a project member' do
      expect(members_mapper.map[exported_user_id]).to eq(user2.id)
    end

    it 'defaults to importer project member if it does not exist' do
      expect(members_mapper.map[-1]).to eq(user.id)
    end

    it 'updates missing author IDs on missing project member' do
      members_mapper.map[-1]

      expect(members_mapper.missing_author_ids.first).to eq(-1)
    end

    it 'has invited members with no user' do
      members_mapper.map

      expect(ProjectMember.find_by_invite_email('invite@test.com')).not_to be_nil
    end
  end
end
