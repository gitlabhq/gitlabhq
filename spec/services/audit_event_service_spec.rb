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

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'has the entity full path' do
        event = service.for_member(project_member).security_event
        expect(event[:details][:entity_path]).to eq(project.full_path)
      end
    end
  end

  describe '#security_event' do
    context 'unlicensed' do
      before do
        stub_licensed_features(audit_events: false)
      end

      it 'does not create an event' do
        expect(SecurityEvent).not_to receive(:create)

        service.security_event
      end
    end

    context 'licensed' do
      it 'creates an event' do
        expect { service.security_event }.to change(SecurityEvent, :count).by(1)
      end
    end
  end

  describe '#audit_events_enabled?' do
    context 'entity is a project' do
      let(:service) { described_class.new(user, project, { action: :destroy }) }

      it 'returns false when project is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.audit_events_enabled?).to be_falsy
      end

      it 'returns true when project is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a group' do
      let(:group) { create(:group) }
      let(:service) { described_class.new(user, group, { action: :destroy }) }

      it 'returns false when group is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.audit_events_enabled?).to be_falsy
      end

      it 'returns true when group is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a user' do
      let(:service) { described_class.new(user, user, { action: :destroy }) }

      it 'returns true when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end
  end
end
