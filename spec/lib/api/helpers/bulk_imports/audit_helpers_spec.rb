# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::BulkImports::AuditHelpers, feature_category: :importers do
  let(:klass) do
    Struct.new(:params) do
      include ::API::Helpers
      include ::API::Helpers::BulkImports::AuditHelpers
    end
  end

  let(:object) { klass.new }

  describe '#log_direct_transfer_audit_event' do
    it 'calls Import::BulkImports::Audit::Auditor' do
      user = build_stubbed(:user)
      project = build_stubbed(:project)

      expect_next_instance_of(Import::BulkImports::Audit::Auditor) do |auditor|
        expect(auditor).to receive(:execute)
      end

      object.log_direct_transfer_audit_event('foo', 'bar', user, project)
    end
  end
end
