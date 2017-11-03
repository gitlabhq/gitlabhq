require 'spec_helper'

describe EE::Audit::GroupChangesAuditor do
  describe '.audit_changes' do
    let!(:user) { create(:user) }
    let!(:group) { create(:group, visibility_level: 0) }
    let(:foo_instance) { described_class.new(user, group) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        group.update!(name: 'new name')

        expect { foo_instance.execute }.not_to change { SecurityEvent.count }
      end
    end

    describe 'audit changes' do
      it 'creates and event when the visibility change' do
        group.update!(visibility_level: 20)

        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:change]).to eq 'visibility'
      end
    end
  end
end
