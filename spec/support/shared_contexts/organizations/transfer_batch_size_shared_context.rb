# frozen_string_literal: true

# Shared context for testing organization transfer services with small batch sizes.
#
# By default, transfer services use large batch sizes (50-1000), so specs with
# only 1-2 records never exercise the batch iteration logic. This context stubs
# all transfer batch constants to 1, ensuring that 3+ records produce multiple
# batches and generate the expected batched SQL queries.
#
# Usage:
#   include_context 'with transfer batch size of 1'
#
RSpec.shared_context 'with transfer batch size of 1' do
  before do
    stub_const('Organizations::Transfer::Concerns::OrganizationUpdater::ORGANIZATION_ID_UPDATE_BATCH_SIZE', 1)
    stub_const('Organizations::Transfer::UsersService::BATCH_SIZE', 1)
    stub_const('Organizations::Transfer::GroupsService::BATCH_SIZE', 1)
    stub_const('Organizations::Transfer::OrganizationUsersService::BATCH_SIZE', 1)
    stub_const('Organizations::Transfer::TopLevelGroupService::BATCH_SIZE', 1)
  end
end
