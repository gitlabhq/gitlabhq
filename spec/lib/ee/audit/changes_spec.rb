require 'spec_helper'

describe EE::Audit::Changes do
  describe '.audit_changes' do
    let(:user) { create(:user) }
    let(:foo_class) { Class.new { include EE::Audit::Changes } }

    before do
      allow_any_instance_of(foo_class).to receive(:model).and_return(user)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        expect_any_instance_of(AuditEventService).not_to receive(:security_event)

        user.update!(name: 'new name')
        foo_class.new.audit_changes(user, :email)
      end
    end

    describe 'audit changes' do
      it 'calls the audit event service' do
        expect_any_instance_of(AuditEventService).to receive(:security_event)

        user.update!(name: 'new name')
        foo_class.new.audit_changes(user, :name)
      end
    end
  end
end
