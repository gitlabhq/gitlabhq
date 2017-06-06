require 'spec_helper'

describe AuditEventService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:project_member) { create(:project_member, user: user) }
  let(:service) { described_class.new(user, project, { action: :destroy }) }

  describe '#for_member' do
    it 'generates event' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq(user.name)
    end

    it 'handles deleted users' do
      expect(project_member).to receive(:user).and_return(nil)

      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq('Deleted User')
    end
    
    it 'has the IP address' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:ip_address]).to eq(user.current_sign_in_ip)
    end

    it 'has the entity full path' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:entity_path]).to eq(project.full_path)
    end
  end
end
