# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteUnitTestsService, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:unit_test_1) { create(:ci_unit_test) }
    let_it_be(:unit_test_2) { create(:ci_unit_test) }
    let_it_be(:unit_test_3) { create(:ci_unit_test) }
    let_it_be(:unit_test_4) { create(:ci_unit_test) }
    let_it_be_with_reload(:unit_test_1_recent_failure) { create(:ci_unit_test_failure, unit_test: unit_test_1) }
    let_it_be(:unit_test_1_old_failure) do
      create(:ci_unit_test_failure, unit_test: unit_test_1, failed_at: 15.days.ago)
    end

    let_it_be(:unit_test_2_old_failure) do
      create(:ci_unit_test_failure, unit_test: unit_test_2, failed_at: 15.days.ago)
    end

    let_it_be(:unit_test_3_old_failure) do
      create(:ci_unit_test_failure, unit_test: unit_test_3, failed_at: 15.days.ago)
    end

    let_it_be(:unit_test_4_old_failure) do
      create(:ci_unit_test_failure, unit_test: unit_test_4, failed_at: 15.days.ago)
    end

    before do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      described_class.new.execute
    end

    it 'deletes old failures and orphaned unit tests, keeping recent failures', :aggregate_failures do
      expect(unit_test_1_recent_failure.reload).to be_persisted

      old_failure_ids = [
        unit_test_1_old_failure,
        unit_test_2_old_failure,
        unit_test_3_old_failure,
        unit_test_4_old_failure
      ].map(&:id)
      expect(Ci::UnitTestFailure.where(id: old_failure_ids)).to be_empty

      orphaned_unit_test_ids = [unit_test_2, unit_test_3, unit_test_4].map(&:id)
      expect(Ci::UnitTest.where(id: orphaned_unit_test_ids)).to be_empty
    end
  end
end
