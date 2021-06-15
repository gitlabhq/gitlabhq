# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::SingleChangeAccess do
  describe '#validate!' do
    include_context 'change access checks context'

    subject { change_access }

    context 'without failed checks' do
      it "doesn't raise an error" do
        expect { subject.validate! }.not_to raise_error
      end

      it 'calls pushes checks' do
        expect_next_instance_of(Gitlab::Checks::PushCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls branches checks' do
        expect_next_instance_of(Gitlab::Checks::BranchCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls tags checks' do
        expect_next_instance_of(Gitlab::Checks::TagCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls diff checks' do
        expect_next_instance_of(Gitlab::Checks::DiffCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end
    end

    context 'when time limit was reached' do
      it 'raises a TimeoutError' do
        logger = Gitlab::Checks::TimedLogger.new(start_time: timeout.ago, timeout: timeout)
        access = described_class.new(changes,
                                     project: project,
                                     user_access: user_access,
                                     protocol: protocol,
                                     logger: logger)

        expect { access.validate! }.to raise_error(Gitlab::Checks::TimedLogger::TimeoutError)
      end
    end
  end
end
