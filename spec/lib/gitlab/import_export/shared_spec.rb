# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Gitlab::ImportExport::Shared do
  let(:project) { build(:project) }

  subject { project.import_export_shared }

  context 'with a repository on disk' do
    let(:project) { create(:project, :repository) }
    let(:base_path) { %(/tmp/gitlab_exports/#{project.disk_path}/) }

    describe '#archive_path' do
      it 'uses a random hash to avoid conflicts' do
        expect(subject.archive_path).to match(/#{base_path}\h{32}/)
      end

      it 'memoizes the path' do
        path = subject.archive_path

        2.times { expect(subject.archive_path).to eq(path) }
      end
    end

    describe '#export_path' do
      it 'uses a random hash relative to project path' do
        expect(subject.export_path).to match(%r{#{base_path}\h{32}/\h{32}})
      end

      it 'memoizes the path' do
        path = subject.export_path

        2.times { expect(subject.export_path).to eq(path) }
      end
    end
  end

  context 'with a group on disk' do
    describe '#base_path' do
      it 'uses hashed storage path' do
        group = create(:group)
        subject = described_class.new(group)
        base_path = %(/tmp/gitlab_exports/@groups/)

        expect(subject.base_path).to match(%r{#{base_path}\h{2}/\h{2}/\h{64}})
      end
    end
  end

  context 'when exportable type is unsupported' do
    describe '#base_path' do
      it 'raises' do
        subject = described_class.new('test')

        expect { subject.base_path }.to raise_error(Gitlab::ImportExport::Error, 'Unsupported Exportable Type String')
      end
    end
  end

  describe '#error' do
    let(:error) { StandardError.new('Error importing into /my/folder Permission denied @ unlink_internal - /var/opt/gitlab/gitlab-rails/shared/a/b/c/uploads/file') }

    it 'filters any full paths' do
      subject.error(error)

      expect(subject.errors).to eq(['Error importing into [FILTERED] Permission denied @ unlink_internal - [FILTERED]'])
    end

    it 'updates the import JID' do
      import_state = create(:import_state, project: project, jid: 'jid-test')

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(error, hash_including(import_jid: import_state.jid))

      subject.error(error)
    end
  end
end
