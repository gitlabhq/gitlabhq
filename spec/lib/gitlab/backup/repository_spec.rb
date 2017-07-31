require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:empty_project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  describe '#dump' do
    describe 'repo failure' do
      before do
        allow_any_instance_of(Repository).to receive(:empty_repo?).and_raise(Rugged::OdbError)
        allow(Gitlab::Popen).to receive(:popen).and_return(['normal output', 0])
      end

      it 'does not raise error' do
        expect { described_class.new.dump }.not_to raise_error
      end

      it 'shows the appropriate error' do
        described_class.new.dump

        expect(progress).to have_received(:puts).with("Ignoring repository error and continuing backing up project: #{project.full_path} - Rugged::OdbError")
      end
    end

    describe 'command failure' do
      before do
        allow_any_instance_of(Repository).to receive(:empty_repo?).and_return(false)
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      it 'shows the appropriate error' do
        described_class.new.dump

        expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
      end
    end
  end

  describe '#restore' do
    describe 'command failure' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      it 'shows the appropriate error' do
        described_class.new.restore

        expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
      end
    end
  end
end
