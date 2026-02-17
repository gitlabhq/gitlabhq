# frozen_string_literal: true

# Shared example for testing organization_id rollback on any records.
# This unified shared example replaces the previous separate examples for
# model records, users, and associated records.
#
# Requires:
#   - let(:service) - the transfer service instance
#   - let(:records) - array of records to verify (models, users, or associated records)
#   - let(:old_organization) - the original organization
#   - before block that stubs a method to raise an error
#
# Example usage:
#   it_behaves_like 'rolls back organization_id updates' do
#     let(:records) { [group, project, user, token] }
#   end
RSpec.shared_examples 'rolls back organization_id updates' do
  context 'when a failure occurs in another part of the service' do
    it 'rolls back organization_id updates due to transaction' do
      begin
        service.execute
      rescue StandardError
        # Expected to raise in some contexts (e.g., when in outer transaction)
      end

      records.each do |record|
        expect(record.reload.organization_id).to eq(old_organization.id)
      end
    end
  end
end

# Shared example for testing visibility_level rollback.
# Requires:
#   - let(:service) - the transfer service instance
#   - let(:model_records) - array of records to verify
#   - let(:original_visibility_levels) - hash mapping record to original visibility level
#   - before block that stubs a method to raise an error
RSpec.shared_examples 'rolls back visibility_level updates for model' do
  context 'when a failure occurs in another part of the service' do
    it 'rolls back visibility level changes due to transaction failure' do
      begin
        service.execute
      rescue StandardError
        # Expected to raise in some contexts
      end

      model_records.each do |record|
        expect(record.reload.visibility_level).to eq(original_visibility_levels[record])
      end
    end
  end
end

# Shared example for testing bot-authored todos rollback.
# Requires:
#   - let(:service) - the transfer service instance
#   - let(:bot_authored_todos) - array of todos authored by bots
#   - let(:original_author_ids) - hash mapping todo to original author_id
#   - before block that stubs a method to raise an error
RSpec.shared_examples 'rolls back bot-authored todo updates' do
  context 'when a failure occurs in another part of the service' do
    it 'rolls back todo author_id changes due to transaction failure' do
      begin
        service.execute
      rescue StandardError
        # Expected to raise in some contexts
      end

      bot_authored_todos.each do |todo|
        expect(todo.reload.author_id).to eq(original_author_ids[todo])
      end
    end
  end
end
