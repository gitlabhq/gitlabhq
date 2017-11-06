shared_examples_for 'audit event logging' do
  before do
    stub_licensed_features(extended_audit_events: true)
  end

  context 'if operation succeed' do
    it 'logs an audit event if operation succeed' do
      expect { operation }.to change(AuditEvent, :count).by(1)
    end

    it 'logs the project info' do
      @resource = operation

      expect(AuditEvent.last).to have_attributes(attributes)
    end
  end

  it 'does not log audit event if project operation fails' do
    fail_condition!

    expect { operation }.not_to change(AuditEvent, :count)
  end
end
