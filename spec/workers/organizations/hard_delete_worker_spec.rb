# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::HardDeleteWorker, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  let(:worker) { described_class.new }
  let(:job_args) { [organization.id, user.id] }

  def log_payload(message, organization_id: organization.id, user_id: user.id, **extras)
    hash_including({
      'class' => 'Organizations::HardDeleteWorker',
      'message' => message,
      Labkit::Fields::GL_ORGANIZATION_ID => organization_id,
      Labkit::Fields::GL_USER_ID => user_id
    }.merge(extras.transform_keys(&:to_s)))
  end

  shared_examples 'no-op when a record is missing' do
    it 'does not call the service' do
      expect(Organizations::HardDeleteService).not_to receive(:new)

      perform
    end

    it 'does not raise an error' do
      expect { perform }.not_to raise_error
    end
  end

  describe '#perform' do
    subject(:perform) { worker.perform(*job_args) }

    context 'when the organization exists' do
      it 'calls Organizations::HardDeleteService#execute' do
        expect_next_instance_of(
          Organizations::HardDeleteService,
          organization,
          current_user: user
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        perform
      end

      it 'disables QueryLimiting for the destructive cascade' do
        allow_next_instance_of(Organizations::HardDeleteService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        expect(Gitlab::QueryLimiting)
          .to receive(:disable!).with('https://gitlab.com/gitlab-org/gitlab/-/issues/594310')

        perform
      end

      context 'when the service returns an error response' do
        it 'logs a warning so the failure is observable' do
          allow_next_instance_of(Organizations::HardDeleteService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'nope'))
          end

          expect(Gitlab::AppLogger).to receive(:warn).with(
            log_payload('Organization hard deletion service returned an error', error_message: 'nope')
          )

          perform
        end
      end
    end

    context 'when the organization does not exist' do
      let(:job_args) { [non_existing_record_id, user.id] }

      include_examples 'no-op when a record is missing'

      it 'logs that the deletion was skipped' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          log_payload('Organization hard deletion skipped: organization not found',
            organization_id: non_existing_record_id)
        )

        perform
      end
    end

    context 'when the user does not exist' do
      let(:job_args) { [organization.id, non_existing_record_id] }

      include_examples 'no-op when a record is missing'

      it 'logs that the deletion was skipped' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          log_payload('Organization hard deletion skipped: user not found',
            user_id: non_existing_record_id)
        )

        perform
      end
    end
  end

  describe 'worker attributes' do
    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'has the correct feature category' do
      expect(described_class.get_feature_category).to eq(:organization)
    end
  end
end
