require 'spec_helper'

describe EE::Audit::Changes do
  describe '.audit_changes' do
    let(:user) { create(:user) }
    let(:foo_instance) { Class.new { include EE::Audit::Changes }.new }

    before do
      foo_instance.instance_variable_set(:@current_user, user)
      allow(foo_instance).to receive(:model).and_return(user)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        expect_any_instance_of(AuditEventService).not_to receive(:security_event)

        user.update!(name: 'new name')
        foo_instance.audit_changes(:email)
      end
    end

    describe 'audit changes' do
      it 'calls the audit event service' do
        expect_any_instance_of(AuditEventService).to receive(:security_event)

        user.update!(name: 'new name')
        foo_instance.audit_changes(:name)
      end
    end
  end
end
