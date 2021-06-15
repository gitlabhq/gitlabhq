# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccess do
  describe '#validate!' do
    include_context 'changes access checks context'

    before do
      allow(project).to receive(:lfs_enabled?).and_return(true)
    end

    subject { changes_access }

    context 'without failed checks' do
      it "doesn't raise an error" do
        expect { subject.validate! }.not_to raise_error
      end

      it 'calls lfs checks' do
        expect_next_instance_of(Gitlab::Checks::LfsCheck) do |instance|
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
