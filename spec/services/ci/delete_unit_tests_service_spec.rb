# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteUnitTestsService do
  describe '#execute' do
    let!(:unit_test_1) { create(:ci_unit_test) }
    let!(:unit_test_2) { create(:ci_unit_test) }
    let!(:unit_test_3) { create(:ci_unit_test) }
    let!(:unit_test_4) { create(:ci_unit_test) }
    let!(:unit_test_1_recent_failure) { create(:ci_unit_test_failure, unit_test: unit_test_1) }
    let!(:unit_test_1_old_failure) { create(:ci_unit_test_failure, unit_test: unit_test_1, failed_at: 15.days.ago) }
    let!(:unit_test_2_old_failure) { create(:ci_unit_test_failure, unit_test: unit_test_2, failed_at: 15.days.ago) }
    let!(:unit_test_3_old_failure) { create(:ci_unit_test_failure, unit_test: unit_test_3, failed_at: 15.days.ago) }
    let!(:unit_test_4_old_failure) { create(:ci_unit_test_failure, unit_test: unit_test_4, failed_at: 15.days.ago) }

    before do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      described_class.new.execute
    end

    it 'does not delete unit test failures not older than 14 days' do
      expect(unit_test_1_recent_failure.reload).to be_persisted
    end

    it 'deletes unit test failures older than 14 days' do
      ids = [
        unit_test_1_old_failure,
        unit_test_2_old_failure,
        unit_test_3_old_failure,
        unit_test_4_old_failure
      ].map(&:id)

      result = Ci::UnitTestFailure.where(id: ids)

      expect(result).to be_empty
    end

    it 'deletes unit tests that have no more associated unit test failures' do
      ids = [
        unit_test_2,
        unit_test_3,
        unit_test_4
      ].map(&:id)

      result = Ci::UnitTest.where(id: ids)

      expect(result).to be_empty
    end
  end
end
