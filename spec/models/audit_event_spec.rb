# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvent do
  let_it_be(:audit_event) { create(:project_audit_event) }
  subject { audit_event }

  describe 'validations' do
    include_examples 'validates IP address' do
      let(:attribute) { :ip_address }
      let(:object) { create(:audit_event) }
    end
  end

  describe '#as_json' do
    context 'ip_address' do
      subject { build(:group_audit_event, ip_address: '192.168.1.1').as_json }

      it 'overrides the ip_address with its string value' do
        expect(subject['ip_address']).to eq('192.168.1.1')
      end
    end
  end
end
