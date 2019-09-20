require 'spec_helper'
require 'fileutils'

describe Gitlab::ImportExport::Shared do
  let(:project) { build(:project) }
  subject { project.import_export_shared }

  describe '#error' do
    let(:error) { StandardError.new('Error importing into /my/folder Permission denied @ unlink_internal - /var/opt/gitlab/gitlab-rails/shared/a/b/c/uploads/file') }

    it 'filters any full paths' do
      subject.error(error)

      expect(subject.errors).to eq(['Error importing into [FILTERED] Permission denied @ unlink_internal - [FILTERED]'])
    end

    it 'updates the import JID' do
      import_state = create(:import_state, project: project, jid: 'jid-test')

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger).to receive(:error).with(hash_including(import_jid: import_state.jid))
      end

      subject.error(error)
    end

    it 'calls the error logger with the full message' do
      expect(subject).to receive(:log_error).with(hash_including(message: error.message))

      subject.error(error)
    end

    it 'calls the debug logger with a backtrace' do
      error.set_backtrace('backtrace')

      expect(subject).to receive(:log_debug).with(hash_including(backtrace: 'backtrace'))

      subject.error(error)
    end
  end
end
