# frozen_string_literal: true

# Requires these let variables to be set by the caller:
# - create_local
# - create_remote
RSpec.shared_examples 'object storable' do
  describe '.with_files_stored_locally' do
    it 'includes states with local storage' do
      create_local

      expect(described_class.with_files_stored_locally).to have_attributes(count: 1)
    end

    it 'excludes states without local storage' do
      create_remote

      expect(described_class.with_files_stored_locally).to have_attributes(count: 0)
    end
  end

  describe '.with_files_stored_remotely' do
    it 'excludes states with local storage' do
      create_local

      expect(described_class.with_files_stored_remotely).to have_attributes(count: 0)
    end

    it 'includes states without local storage' do
      create_remote

      expect(described_class.with_files_stored_remotely).to have_attributes(count: 1)
    end
  end
end
