# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Instrumentation do
  describe '#observe' do
    subject { described_class.new }

    let(:migration) { 1234 }

    it 'executes the given block' do
      expect { |b| subject.observe(migration, &b) }.to yield_control
    end

    context 'on successful execution' do
      subject { described_class.new.observe(migration) {} }

      it 'records walltime' do
        expect(subject.walltime).not_to be_nil
      end

      it 'records success' do
        expect(subject.success).to be_truthy
      end

      it 'records the migration version' do
        expect(subject.migration).to eq(migration)
      end
    end

    context 'upon failure' do
      subject { described_class.new.observe(migration) { raise 'something went wrong' } }

      it 'raises the exception' do
        expect { subject }.to raise_error(/something went wrong/)
      end

      context 'retrieving observations' do
        subject { instance.observations.first }

        before do
          instance.observe(migration) { raise 'something went wrong' }
        rescue
          # ignore
        end

        let(:instance) { described_class.new }

        it 'records walltime' do
          expect(subject.walltime).not_to be_nil
        end

        it 'records failure' do
          expect(subject.success).to be_falsey
        end

        it 'records the migration version' do
          expect(subject.migration).to eq(migration)
        end
      end
    end

    context 'sequence of migrations with failures' do
      subject { described_class.new }

      let(:migration1) { double('migration1', call: nil) }
      let(:migration2) { double('migration2', call: nil) }

      it 'records observations for all migrations' do
        subject.observe('migration1') {}
        subject.observe('migration2') { raise 'something went wrong' } rescue nil

        expect(subject.observations.size).to eq(2)
      end
    end
  end
end
