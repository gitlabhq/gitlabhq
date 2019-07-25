# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DowntimeCheck do
  subject { described_class.new }
  let(:path) { 'foo.rb' }

  describe '#check' do
    before do
      expect(subject).to receive(:require).with(path)
    end

    context 'when a migration does not specify if downtime is required' do
      it 'raises RuntimeError' do
        expect(subject).to receive(:class_for_migration_file)
          .with(path)
          .and_return(Class.new)

        expect { subject.check([path]) }
          .to raise_error(RuntimeError, /it requires downtime/)
      end
    end

    context 'when a migration requires downtime' do
      context 'when no reason is specified' do
        it 'raises RuntimeError' do
          stub_const('TestMigration::DOWNTIME', true)

          expect(subject).to receive(:class_for_migration_file)
            .with(path)
            .and_return(TestMigration)

          expect { subject.check([path]) }
            .to raise_error(RuntimeError, /no reason was given/)
        end
      end

      context 'when a reason is specified' do
        it 'returns an Array of messages' do
          stub_const('TestMigration::DOWNTIME', true)
          stub_const('TestMigration::DOWNTIME_REASON', 'foo')

          expect(subject).to receive(:class_for_migration_file)
            .with(path)
            .and_return(TestMigration)

          messages = subject.check([path])

          expect(messages).to be_an_instance_of(Array)
          expect(messages[0]).to be_an_instance_of(Gitlab::DowntimeCheck::Message)

          message = messages[0]

          expect(message.path).to eq(path)
          expect(message.offline).to eq(true)
          expect(message.reason).to eq('foo')
        end
      end
    end
  end

  describe '#check_and_print' do
    it 'checks the migrations and prints the results to STDOUT' do
      stub_const('TestMigration::DOWNTIME', true)
      stub_const('TestMigration::DOWNTIME_REASON', 'foo')

      expect(subject).to receive(:require).with(path)

      expect(subject).to receive(:class_for_migration_file)
        .with(path)
        .and_return(TestMigration)

      expect(subject).to receive(:puts).with(an_instance_of(String))

      subject.check_and_print([path])
    end
  end

  describe '#class_for_migration_file' do
    it 'returns the class for a migration file path' do
      expect(subject.class_for_migration_file('123_string.rb')).to eq(String)
    end
  end

  describe '#online?' do
    it 'returns true when a migration can be performed online' do
      stub_const('TestMigration::DOWNTIME', false)

      expect(subject.online?(TestMigration)).to eq(true)
    end

    it 'returns false when a migration can not be performed online' do
      stub_const('TestMigration::DOWNTIME', true)

      expect(subject.online?(TestMigration)).to eq(false)
    end
  end

  describe '#downtime_reason' do
    context 'when a reason is defined' do
      it 'returns the downtime reason' do
        stub_const('TestMigration::DOWNTIME_REASON', 'hello')

        expect(subject.downtime_reason(TestMigration)).to eq('hello')
      end
    end

    context 'when a reason is not defined' do
      it 'returns nil' do
        expect(subject.downtime_reason(Class.new)).to be_nil
      end
    end
  end
end
