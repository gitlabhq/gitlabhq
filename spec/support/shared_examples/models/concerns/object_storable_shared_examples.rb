# frozen_string_literal: true

# Requires these let variables to be set by the caller:
# - locally_stored
# - remotely_stored
RSpec.shared_examples 'object storable' do
  describe '.with_files_stored_locally' do
    it 'includes locally stored files' do
      expect(described_class.with_files_stored_locally).to include(*locally_stored)
    end

    it 'excludes remotely stored files' do
      expect(described_class.with_files_stored_locally).not_to include(*remotely_stored)
    end
  end

  describe '.with_files_stored_remotely' do
    it 'includes remotely stored files' do
      expect(described_class.with_files_stored_remotely).to include(*remotely_stored)
    end

    it 'excludes locally stored files' do
      expect(described_class.with_files_stored_remotely).not_to include(*locally_stored)
    end
  end
end
