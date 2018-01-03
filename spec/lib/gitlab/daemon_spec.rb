require 'spec_helper'

describe Gitlab::Daemon do
  subject { described_class.new }

  before do
    allow(subject).to receive(:start_working)
    allow(subject).to receive(:stop_working)
  end

  describe '.instance' do
    before do
      allow(Kernel).to receive(:at_exit)
    end

    after do
      described_class.instance_variable_set(:@instance, nil)
    end

    it 'provides instance of Daemon' do
      expect(described_class.instance).to be_instance_of(described_class)
    end

    it 'subsequent invocations provide the same instance' do
      expect(described_class.instance).to eq(described_class.instance)
    end

    it 'creates at_exit hook when instance is created' do
      expect(described_class.instance).not_to be_nil

      expect(Kernel).to have_received(:at_exit)
    end
  end

  describe 'when Daemon is enabled' do
    before do
      allow(subject).to receive(:enabled?).and_return(true)
    end

    describe 'when Daemon is stopped' do
      describe '#start' do
        it 'starts the Daemon' do
          expect { subject.start.join }.to change { subject.thread? }.from(false).to(true)

          expect(subject).to have_received(:start_working)
        end
      end

      describe '#stop' do
        it "doesn't shutdown stopped Daemon" do
          expect { subject.stop }.not_to change { subject.thread? }

          expect(subject).not_to have_received(:start_working)
        end
      end
    end

    describe 'when Daemon is running' do
      before do
        subject.start.join
      end

      describe '#start' do
        it "doesn't start running Daemon" do
          expect { subject.start.join }.not_to change { subject.thread? }

          expect(subject).to have_received(:start_working).once
        end
      end

      describe '#stop' do
        it 'shutdowns Daemon' do
          expect { subject.stop }.to change { subject.thread? }.from(true).to(false)

          expect(subject).to have_received(:stop_working)
        end
      end
    end
  end

  describe 'when Daemon is disabled' do
    before do
      allow(subject).to receive(:enabled?).and_return(false)
    end

    describe '#start' do
      it "doesn't start working" do
        expect(subject.start).to be_nil
        expect { subject.start }.not_to change { subject.thread? }

        expect(subject).not_to have_received(:start_working)
      end
    end

    describe '#stop' do
      it "doesn't stop working" do
        expect { subject.stop }.not_to change { subject.thread? }

        expect(subject).not_to have_received(:stop_working)
      end
    end
  end
end
