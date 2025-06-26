# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::Audit::Auditor, feature_category: :importers do
  let(:user) { build_stubbed(:user) }
  let(:scope) { build_stubbed(:project) }
  let(:event_name) { ::Import::BulkImports::Audit::Events::EXPORT_INITIATED }
  let(:event_message) { 'message' }

  subject(:auditor) do
    described_class.new(
      event_name: event_name,
      event_message: event_message,
      current_user: user,
      scope: scope
    )
  end

  describe '#execute' do
    shared_examples 'new audit event' do
      it 'creates new audit event' do
        expect(::Gitlab::Audit::Auditor)
          .to receive(:audit)
          .with(
            name: event_name,
            author: user,
            scope: scope,
            target: scope,
            message: event_message
          )

        auditor.execute
      end
    end

    include_examples 'new audit event'

    context 'when target is group' do
      let(:scope) { build_stubbed(:group) }

      include_examples 'new audit event'
    end

    describe 'silent admin export' do
      let(:scope) { build_stubbed(:group) }

      before do
        stub_application_setting(silent_admin_exports_enabled: true)
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it 'does not create audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        auditor.execute
      end

      context 'when not export event' do
        let(:event_name) { 'event' }

        include_examples 'new audit event'
      end

      context 'when user is not admin' do
        before do
          allow(user).to receive(:can_admin_all_resources?).and_return(false)
        end

        include_examples 'new audit event'
      end

      context 'when silent admin exports application setting is disabled' do
        before do
          stub_application_setting(silent_admin_exports_enabled: false)
        end

        include_examples 'new audit event'
      end
    end
  end
end
