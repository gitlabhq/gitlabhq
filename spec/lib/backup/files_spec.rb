require 'spec_helper'

describe Backup::Files do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
    allow(FileUtils).to receive(:mkdir_p).and_return(true)
    allow(FileUtils).to receive(:mv).and_return(true)
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:realpath).with("/var/gitlab-registry").and_return("/var/gitlab-registry")
    allow(File).to receive(:realpath).with("/var/gitlab-registry/..").and_return("/var")

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  describe '#restore' do
    subject { described_class.new('registry', '/var/gitlab-registry') }
    let(:timestamp) { Time.utc(2017, 3, 22) }

    around do |example|
      Timecop.freeze(timestamp) { example.run }
    end

    describe 'folders with permission' do
      before do
        allow(subject).to receive(:run_pipeline!).and_return(true)
        allow(subject).to receive(:backup_existing_files).and_return(true)
        allow(Dir).to receive(:glob).with("/var/gitlab-registry/*", File::FNM_DOTMATCH).and_return(["/var/gitlab-registry/.", "/var/gitlab-registry/..", "/var/gitlab-registry/sample1"])
      end

      it 'moves all necessary files' do
        allow(subject).to receive(:backup_existing_files).and_call_original
        expect(FileUtils).to receive(:mv).with(["/var/gitlab-registry/sample1"], File.join(Gitlab.config.backup.path, "tmp", "registry.#{Time.now.to_i}"))
        subject.restore
      end

      it 'raises no errors' do
        expect { subject.restore }.not_to raise_error
      end

      it 'calls tar command with unlink' do
        expect(subject).to receive(:run_pipeline!).with([%w(gzip -cd), %w(tar --unlink-first --recursive-unlink -C /var/gitlab-registry -xf -)], any_args)
        subject.restore
      end
    end

    describe 'folders without permissions' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
        allow(subject).to receive(:run_pipeline!).and_return(true)
      end

      it 'shows error message' do
        expect(subject).to receive(:access_denied_error).with("/var/gitlab-registry")
        subject.restore
      end
    end
  end
end
