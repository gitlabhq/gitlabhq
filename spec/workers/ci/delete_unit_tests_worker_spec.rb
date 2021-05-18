# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteUnitTestsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(Ci::DeleteUnitTestsService) do |instance|
        expect(instance).to receive(:execute)
      end

      worker.perform
    end
  end

  it_behaves_like 'an idempotent worker' do
    let!(:unit_test_1) { create(:ci_unit_test) }
    let!(:unit_test_2) { create(:ci_unit_test) }
    let!(:unit_test_1_recent_failure) { create(:ci_unit_test_failure, unit_test: unit_test_1) }
    let!(:unit_test_2_old_failure) { create(:ci_unit_test_failure, unit_test: unit_test_2, failed_at: 15.days.ago) }

    it 'only deletes old unit tests and their failures' do
      subject

      expect(unit_test_1.reload).to be_persisted
      expect(unit_test_1_recent_failure.reload).to be_persisted
      expect(Ci::UnitTest.find_by(id: unit_test_2.id)).to be_nil
      expect(Ci::UnitTestFailure.find_by(id: unit_test_2_old_failure.id)).to be_nil
    end
  end
end
