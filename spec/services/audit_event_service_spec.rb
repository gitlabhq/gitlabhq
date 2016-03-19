require 'spec_helper'

describe AuditEventService, services: true do
  let(:project) { create(:project) }
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
  end
end
