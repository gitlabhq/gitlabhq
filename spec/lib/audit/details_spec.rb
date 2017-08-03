require 'spec_helper'

describe Audit::Details do
  let(:user) { create(:user) }
  
  describe '.humanize' do
    context 'user' do
      let(:login_action) do
        {
          with: :ldap,
          target_id: user.id,
          target_type: 'User',
          target_details: user.name
        }
      end
      
      it 'humanizes user login action' do
        expect(described_class.humanize(login_action)).to eq('Signed in with LDAP authentication')
      end
    end
    
    context 'project' do
      let(:user_member) { create(:user) }
      let(:project) { create(:project) }
      let(:member) { create(:project_member, :developer, user: user_member, project: project) }
      let(:member_access_action) do
        {
          add: 'user_access',
          as: Gitlab::Access.options_with_owner.key(member.access_level.to_i),
          author_name: user.name,
          target_id: member.id,
          target_type: 'User',
          target_details: member.user.name
        }
      end
      
      it 'humanizes add project member access action' do
        expect(described_class.humanize(member_access_action)).to eq('Added user access as Developer')
      end
    end
    
    context 'group' do
      let(:user_member) { create(:user) }
      let(:group) { create(:group) }
      let(:member) { create(:group_member, group: group, user: user_member) }
      let(:member_access_action) do
        {
          change: 'access_level',
          from: 'Guest',
          to: member.human_access,
          author_name: user.name,
          target_id: member.id,
          target_type: 'User',
          target_details: member.user.name
        }
      end
      
      it 'humanizes add group member access action' do
        expect(described_class.humanize(member_access_action)).to eq('Changed access level from Guest to Owner')
      end
    end
    
    context 'deploy key' do
      let(:removal_action) do
        {
          remove: 'deploy_key',
          author_name: user.name,
          target_id: 'key title',
          target_type: 'DeployKey',
          target_details: 'key title'
        }
      end

      it 'humanizes the removal action' do
        expect(described_class.humanize(removal_action)).to eq('Removed deploy key')
      end
    end
  end
end
