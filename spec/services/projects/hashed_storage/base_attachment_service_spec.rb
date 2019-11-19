# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::BaseAttachmentService do
  let(:project) { create(:project, :repository, storage_version: 0, skip_disk_validation: true) }

  subject(:service) { described_class.new(project: project, old_disk_path: project.full_path, logger: nil) }

  describe '#old_disk_path' do
    it { is_expected.to respond_to :old_disk_path }
  end

  describe '#new_disk_path' do
    it { is_expected.to respond_to :new_disk_path }
  end

  describe '#skipped?' do
    it { is_expected.to respond_to :skipped? }
  end

  describe '#target_path_discardable?' do
    it 'returns false' do
      expect(subject.target_path_discardable?('something/something')).to be_falsey
    end
  end

  describe '#discard_path!' do
    it 'renames target path adding a timestamp at the end' do
      target_path = Dir.mktmpdir
      expect(Dir.exist?(target_path)).to be_truthy

      Timecop.freeze do
        suffix = Time.now.utc.to_i
        subject.send(:discard_path!, target_path)

        expected_renamed_path = "#{target_path}-#{suffix}"

        expect(Dir.exist?(target_path)).to be_falsey
        expect(Dir.exist?(expected_renamed_path)).to be_truthy
      end
    end
  end

  describe '#move_folder!' do
    context 'when old_path is not a directory' do
      it 'adds information to the logger and returns true' do
        Tempfile.create do |old_path|
          new_path = "#{old_path}-new"

          expect(subject.send(:move_folder!, old_path, new_path)).to be_truthy
        end
      end
    end
  end
end
