require 'spec_helper'

describe EE::Audit::Changes do
  describe '.audit_changes' do
    let(:user) { create(:user) }
    let(:foo_instance) { Class.new { include EE::Audit::Changes }.new }

    before do
      stub_licensed_features(extended_audit_events: true)

      foo_instance.instance_variable_set(:@current_user, user)
      foo_instance.instance_variable_set(:@user, user)

      allow(foo_instance).to receive(:model).and_return(user)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        user.update!(name: 'new name')

        expect { foo_instance.audit_changes(:email) }.not_to change { SecurityEvent.count }
      end
    end

    describe 'audit changes' do
      it 'calls the audit event service' do
        user.update!(name: 'new name')

        expect { foo_instance.audit_changes(:name) }.to change { SecurityEvent.count }.by(1)
      end
    end
  end
end
