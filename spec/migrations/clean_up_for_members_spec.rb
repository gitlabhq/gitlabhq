require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171216111734_clean_up_for_members.rb')

describe CleanUpForMembers, :migration do
  let(:migration) { described_class.new }
  let!(:group_member) { create_group_member }
  let!(:unbinded_group_member) { create_group_member }
  let!(:invited_group_member) { create_group_member(true) }
  let!(:not_valid_group_member) { create_group_member }
  let!(:project_member) { create_project_member }
  let!(:invited_project_member) { create_project_member(true) }
  let!(:unbinded_project_member) { create_project_member }
  let!(:not_valid_project_member) { create_project_member }

  it 'removes members without proper user_id' do
    unbinded_group_member.update_column(:user_id, nil)
    not_valid_group_member.update_column(:user_id, 9999)
    unbinded_project_member.update_column(:user_id, nil)
    not_valid_project_member.update_column(:user_id, 9999)

    migrate!

    expect(Member.all).not_to include(unbinded_group_member, not_valid_group_member, unbinded_project_member, not_valid_project_member)
    expect(Member.all).to include(group_member, invited_group_member, project_member, invited_project_member)
  end

  def create_group_member(invited = false)
    fill_member(GroupMember.new(group: create_group), invited)
  end

  def create_project_member(invited = false)
    fill_member(ProjectMember.new(project: create_project), invited)
  end

  def fill_member(member_object, invited)
    member_object.tap do |m|
      m.access_level = 40
      m.notification_level = 3

      if invited
        m.user_id = nil
        m.invite_token = 'xxx'
        m.invite_email = 'email@email.com'
      else
        m.user_id = create_user.id
      end

      m.save
    end

    member_object
  end

  def create_group
    name = FFaker::Lorem.characters(10)

    Group.create(name: name, path: name.downcase.gsub(/\s/, '_'))
  end

  def create_project
    name = FFaker::Lorem.characters(10)
    creator = create_user

    Project.create(name: name,
                   path: name.downcase.gsub(/\s/, '_'),
                   namespace: creator.namespace,
                   creator: creator)
  end

  def create_user
    User.create(email: FFaker::Internet.email,
                password: '12345678',
                name: FFaker::Name.name,
                username: FFaker::Internet.user_name,
                confirmed_at: Time.now,
                confirmation_token: nil)
  end
end
