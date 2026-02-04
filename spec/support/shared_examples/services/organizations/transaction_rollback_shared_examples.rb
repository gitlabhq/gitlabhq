# frozen_string_literal: true

# Generic shared example for testing transaction rollback of any attribute.
# This is the most flexible shared example - use the more specific ones when possible.
#
# Parameters:
#   - service: the transfer service instance
#   - records: array of records to verify
#   - attribute: the attribute name to check (e.g., :organization_id, :visibility_level)
#   - expected_value: the value records should have after rollback
#   - failure_method: method to stub to cause failure
#   - error_message: error message for the raised exception
#
# Example usage:
#   it_behaves_like 'organization transfer service transaction rollback',
#     service: service,
#     records: [group, subgroup, project],
#     attribute: :organization_id,
#     expected_value: old_organization.id,
#     failure_method: :transfer_users,
#     error_message: 'User transfer failed'
#
# rubocop:disable Layout/LineLength -- parameter list is clearer on one conceptual line
RSpec.shared_examples 'organization transfer service transaction rollback' do |service:, records:, attribute:, expected_value:, failure_method:, error_message:|
  # rubocop:enable Layout/LineLength
  it "rolls back #{attribute} updates for records due to transaction failure" do
    # Stub the failure method to raise an error
    allow(service).to receive(failure_method).and_raise(StandardError, error_message)

    # Execute the service and expect it to handle the error
    begin
      service.execute
    rescue StandardError
      # Expected to raise in some contexts
    end

    # Verify all records were rolled back to expected value
    records.each do |record|
      expect(record.reload.public_send(attribute)).to eq(expected_value)
    end
  end
end

# Shared example for verifying an attribute does not change during failed transfer.
# Uses expect { }.not_to change pattern.
#
# Requires:
#   - let(:service) - the transfer service instance
#   - let(:record) - the record to verify
#   - let(:attribute) - the attribute to check
#   - before block that stubs a method to raise an error
#
# Example usage:
#   it_behaves_like 'does not change attribute on failed transfer' do
#     let(:record) { user }
#     let(:attribute) { :organization_id }
#   end
RSpec.shared_examples 'does not change attribute on failed transfer' do
  it "does not change #{attribute} due to transaction failure" do
    expect do
      service.execute
    rescue StandardError
      # Expected to raise in some contexts
    end.not_to change { record.reload.public_send(attribute) }
  end
end

# Shared example for testing multiple attributes rollback on a single record.
# Useful when a record has multiple attributes updated during transfer.
#
# Requires:
#   - let(:service) - the transfer service instance
#   - let(:record) - the record to verify
#   - let(:original_attributes) - hash of attribute => original_value
#   - before block that stubs a method to raise an error
#
# Example usage:
#   it_behaves_like 'rolls back multiple attributes on record' do
#     let(:record) { project }
#     let(:original_attributes) do
#       { organization_id: old_organization.id, visibility_level: Gitlab::VisibilityLevel::PUBLIC }
#     end
#   end
RSpec.shared_examples 'rolls back multiple attributes on record' do
  context 'when a failure occurs in another part of the service' do
    it 'rolls back all attribute changes due to transaction failure' do
      begin
        service.execute
      rescue StandardError
        # Expected to raise in some contexts
      end

      original_attributes.each do |attr, expected_value|
        expect(record.reload.public_send(attr)).to eq(expected_value),
          "Expected #{attr} to be #{expected_value}, got #{record.public_send(attr)}"
      end
    end
  end
end

# Helper shared context for setting up transaction rollback test scenarios.
# Provides common setup for stubbing failure methods.
#
# Parameters:
#   - failure_target: the object to stub (e.g., service, or a class)
#   - failure_method: the method to stub
#   - error_class: the error class to raise (default: StandardError)
#   - error_message: the error message (default: 'Simulated failure for rollback test')
#
# Example usage:
#   include_context 'with transaction rollback setup',
#     failure_target: :service,
#     failure_method: :transfer_users
#
# rubocop:disable Layout/LineLength -- parameter list is clearer on one conceptual line
RSpec.shared_context 'with transaction rollback setup' do |failure_target:, failure_method:, error_class: StandardError, error_message: 'Simulated failure for rollback test'|
  # rubocop:enable Layout/LineLength
  before do
    target = failure_target.is_a?(Symbol) ? send(failure_target) : failure_target
    allow(target).to receive(failure_method).and_raise(error_class, error_message)
  end
end
