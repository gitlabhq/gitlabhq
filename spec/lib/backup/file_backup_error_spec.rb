# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::FileBackupError do
  let_it_be(:lfs) { create(:lfs_object) }
  let_it_be(:upload) { create(:upload) }

  let(:backup_tarball) { '/tmp/backup/uploads' }

  shared_examples 'includes backup path' do
    it { is_expected.to respond_to :storage_path }
    it { is_expected.to respond_to :backup_tarball }

    it 'expects exception message to include file backup path location' do
      expect(subject.message).to include(subject.backup_tarball.to_s)
    end

    it 'expects exception message to include file being back-up' do
      expect(subject.message).to include(subject.storage_path.to_s)
    end
  end

  context 'with lfs file' do
    subject { described_class.new(lfs, backup_tarball) }

    it_behaves_like 'includes backup path'
  end

  context 'with uploads file' do
    subject { described_class.new(upload, backup_tarball) }

    it_behaves_like 'includes backup path'
  end
end
