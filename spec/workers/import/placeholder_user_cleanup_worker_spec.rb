# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderUserCleanupWorker, feature_category: :importers do
  let(:max_attempts) { described_class::MAX_ATTEMPTS }

  let!(:eligible_detail_one) do
    create(:import_placeholder_user_details,
      :eligible_for_deletion
    )
  end

  let!(:eligible_detail_two) do
    create(:import_placeholder_user_details,
      :eligible_for_deletion,
      deletion_attempts: 0
    )
  end

  let!(:recently_atttempted_detail) do
    create(:import_placeholder_user_details,
      last_deletion_attempt_at: 1.day.ago
    )
  end

  let!(:max_attempts_detail) do
    create(:import_placeholder_user_details,
      namespace: nil,
      deletion_attempts: max_attempts,
      last_deletion_attempt_at: 3.days.ago
    )
  end

  subject(:perform) { described_class.new.perform }

  describe '#perform' do
    it_behaves_like 'an idempotent worker'

    context 'when there are eligible placeholder users marked for deletion' do
      it 'schedules a delete worker for each eligible placeholder user with delays' do
        expect(Import::DeletePlaceholderUserWorker).to receive(:perform_in)
          .with(anything, eligible_detail_one.placeholder_user_id, { type: 'placeholder_user' })
        expect(Import::DeletePlaceholderUserWorker).to receive(:perform_in)
          .with(anything, eligible_detail_two.placeholder_user_id, { type: 'placeholder_user' })

        expect(Import::DeletePlaceholderUserWorker).not_to receive(:perform_in)
          .with(anything, recently_atttempted_detail.placeholder_user_id, { type: 'placeholder_user' })
        expect(Import::DeletePlaceholderUserWorker).not_to receive(:perform_in)
          .with(anything, max_attempts_detail.placeholder_user_id, { type: 'placeholder_user' })

        perform
      end

      it 'increments the deletion_attempts counter for each processed detail', :freeze_time do
        perform

        expect(eligible_detail_one.reload.deletion_attempts).to eq(3)
        expect(eligible_detail_one.reload.last_deletion_attempt_at).to eq(Time.current)

        expect(eligible_detail_two.reload.deletion_attempts).to eq(1)
        expect(eligible_detail_two.reload.last_deletion_attempt_at).to eq(Time.current)

        expect(recently_atttempted_detail.reload.deletion_attempts).to eq(0)
        expect(max_attempts_detail.reload.deletion_attempts).to eq(max_attempts)
      end

      it 'logs a warning when deletion attempts reach the maximum' do
        almost_max_detail = create(
          :import_placeholder_user_details,
          deletion_attempts: max_attempts - 1,
          namespace: nil,
          last_deletion_attempt_at: 3.days.ago
        )

        expect(::Import::Framework::Logger).to receive(:warn).with(
          message: "Maximum deletion attempts (#{max_attempts}) reached for deletion of placeholder user." \
            "Making final deletion attempt.",
          placeholder_user_id: almost_max_detail.placeholder_user_id
        )

        perform
      end
    end

    context 'when there are no eligible placeholder users marked for deletion' do
      before do
        namespace = create(:namespace)
        eligible_detail_one.update!(namespace: namespace)
        eligible_detail_two.update!(namespace: namespace)
      end

      it 'does not schedule any delete workers' do
        expect(Import::DeletePlaceholderUserWorker).not_to receive(:perform_in)

        perform
      end

      it 'does not update any details' do
        expect { perform }.not_to change {
          eligible_detail_one.reload.deletion_attempts
          eligible_detail_one.reload.last_deletion_attempt_at
          eligible_detail_two.reload.deletion_attempts
          eligible_detail_two.reload.last_deletion_attempt_at
          recently_atttempted_detail.reload.deletion_attempts
          recently_atttempted_detail.reload.last_deletion_attempt_at
        }
      end
    end
  end
end
