# frozen_string_literal: true

# Requires:
#   - let(:group), let(:old_organization), let(:new_organization) - the records passed to the service
RSpec.shared_examples 'an organization transfer service handling missing records' do
  using RSpec::Parameterized::TableSyntax

  def execute_with(**overrides)
    records = { group: group, old_organization: old_organization, new_organization: new_organization }

    described_class.new(**records.merge(overrides)).execute
  end

  it 'returns a success response when all records are present' do
    expect(execute_with).to be_success
  end

  where(:missing_record, :message) do
    :group            | 'Group not found.'
    :old_organization | 'Old organization not found.'
    :new_organization | 'New organization not found.'
  end

  with_them do
    it 'logs and returns a not found error without querying the database' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(Labkit::Fields::CLASS_NAME => described_class.name, 'message' => message)
      )

      result = nil
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { result = execute_with(missing_record => nil) }

      expect(recorder.count).to eq(0)
      expect(result).to be_error
      expect(result.message).to eq(message)
      expect(result.reason).to eq(:not_found)
    end
  end
end
