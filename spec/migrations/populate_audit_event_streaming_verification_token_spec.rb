# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateAuditEventStreamingVerificationToken, feature_category: :audit_events do
  let(:groups) { table(:namespaces) }
  let(:destinations) { table(:audit_events_external_audit_event_destinations) }
  let(:migration) { described_class.new }

  let!(:group) { groups.create!(name: 'test-group', path: 'test-group') }
  let!(:destination) { destinations.create!(namespace_id: group.id, destination_url: 'https://example.com/destination', verification_token: nil) }

  describe '#up' do
    it 'adds verification tokens to records created before the migration' do
      expect do
        migrate!
        destination.reload
      end.to change { destination.verification_token }.from(nil).to(a_string_matching(/\w{24}/))
    end
  end
end
