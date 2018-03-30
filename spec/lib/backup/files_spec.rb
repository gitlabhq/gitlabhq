require 'spec_helper'

describe Backup::Files do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
    allow(FileUtils).to receive(:mkdir_p).and_return(true)
    allow(FileUtils).to receive(:mv).and_return(true)

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

    describe 'folders without permissions' do
      before do
        allow(File).to receive(:realpath).with("/var/gitlab-registry").and_return("/var/gitlab-registry")
        allow(File).to receive(:realpath).with("/var/gitlab-registry/..").and_return("/var")
        allow(File).to receive(:exist?).and_return(true)
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
