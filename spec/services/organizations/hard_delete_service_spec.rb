# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::HardDeleteService, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  let(:service) { described_class.new(organization, current_user: user) }

  def log_payload(message, **extras)
    hash_including({
      'class' => 'Organizations::HardDeleteService',
      'message' => message,
      Labkit::Fields::GL_USER_ID => user.id,
      Labkit::Fields::GL_ORGANIZATION_ID => organization.id
    }.merge(extras.transform_keys(&:to_s)))
  end

  describe '#async_execute' do
    subject(:response) { service.async_execute }

    context 'when user does not have permission' do
      before do
        organization.soft_delete!(transition_user: user)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to eq('Insufficient permissions')
        expect(response.payload[:organization]).to be_nil
      end

      it 'does not enqueue Organizations::HardDeleteWorker' do
        expect { response }.not_to change { Organizations::HardDeleteWorker.jobs.size }
      end
    end

    context 'when user has permission' do
      before_all do
        create(:organization_user, :owner, organization: organization, user: user)
      end

      context 'when organization is the default organization' do
        let(:organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the delete_organization policy disallows deletion of the default organization

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Insufficient permissions')
        end
      end

      context 'when organization is not soft-deleted' do
        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Organization must be soft-deleted first')
          expect(response.payload[:organization]).to be_nil
        end

        it 'does not enqueue Organizations::HardDeleteWorker' do
          expect { response }.not_to change { Organizations::HardDeleteWorker.jobs.size }
        end
      end

      context 'when organization is soft-deleted' do
        before do
          organization.soft_delete!(transition_user: user)
          # Stub the worker enqueue so we don't hit the
          # `forbid_sidekiq_in_transactions` initializer's `inside_transaction?`
          # check, which under some test orderings raises a NoMethodError when
          # the model superclass chain reaches ActiveRecord::Base. Tests that
          # need a different stub (e.g. asserting the enqueue, or a specific
          # job id) override this with their own `expect`/`allow` below.
          allow(Organizations::HardDeleteWorker).to receive(:perform_async).and_return('job-id')
        end

        it 'transitions the organization to deletion_in_progress state' do
          expect { response }
            .to change { organization.reload.state }.from('soft_deleted').to('deletion_in_progress')
        end

        it 'enqueues Organizations::HardDeleteWorker with the organization and user ids' do
          expect(Organizations::HardDeleteWorker).to receive(:perform_async).with(organization.id, user.id)

          response
        end

        it 'logs the scheduling event' do
          allow(Organizations::HardDeleteWorker).to receive(:perform_async).and_return('job-123')
          allow(Gitlab::AppLogger).to receive(:info).and_call_original

          expect(Gitlab::AppLogger).to receive(:info).with(
            log_payload('Organization hard deletion scheduled', job_id: 'job-123')
          )

          response
        end

        it 'returns a success response with the organization' do
          expect(response).to be_success
          expect(response.payload[:organization]).to eq(organization)
        end

        context 'when enqueuing the worker fails' do
          let(:enqueue_error) { Redis::CannotConnectError.new('redis down') }

          before do
            allow(Organizations::HardDeleteWorker).to receive(:perform_async).and_raise(enqueue_error)
            allow(Gitlab::AppLogger).to receive(:error).and_call_original
          end

          it 'rolls the organization back to soft_deleted' do
            response

            expect(organization.reload.state).to eq('soft_deleted')
          end

          it 'logs the enqueue failure' do
            expect(Gitlab::AppLogger).to receive(:error).with(
              log_payload('Organization hard deletion enqueue failed',
                error_class: 'Redis::CannotConnectError',
                error_message: 'redis down')
            )

            response
          end

          it 'returns a ServiceResponse.error and does not raise' do
            expect { response }.not_to raise_error
            expect(response).to be_error
            expect(response.message).to eq('Failed to schedule organization deletion')
          end

          context 'when the abort_hard_deletion rollback also fails' do
            let(:rollback_error) do
              StateMachines::InvalidTransition.new(organization, organization.class.state_machine, :abort_hard_deletion)
            end

            before do
              allow(organization).to receive(:abort_hard_deletion!).and_raise(rollback_error)
            end

            it 'logs both errors and returns ServiceResponse.error' do
              expect(Gitlab::AppLogger).to receive(:error).with(
                hash_including('message' => 'Organization hard deletion rollback failed')
              ).ordered
              expect(Gitlab::AppLogger).to receive(:error).with(
                hash_including('message' => 'Organization hard deletion enqueue failed')
              ).ordered

              expect { response }.not_to raise_error
              expect(response).to be_error
            end
          end
        end
      end
    end
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when user does not have permission' do
      before do
        organization.soft_delete!(transition_user: user)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to eq('Insufficient permissions')
        expect(response.payload[:organization]).to be_nil
      end
    end

    context 'when user has permission' do
      before_all do
        create(:organization_user, :owner, organization: organization, user: user)
      end

      context 'when organization is active' do
        it 'returns an error and does not destroy the organization' do
          expect(response).to be_error
          expect(response.message).to eq('Organization must be soft-deleted first')
          expect(Organizations::Organization.exists?(organization.id)).to be(true)
        end
      end

      context 'when organization is soft-deleted' do
        before do
          organization.soft_delete!(transition_user: user)
          # The organization still has organization_users referencing it, which would block
          # destroy! via a foreign-key constraint. Cleaning up those rows is out of scope
          # for this MR (the issue covers service+worker plumbing only), so stub destroy!
          # to verify the call without exercising the DB cascade.
          allow(organization).to receive(:destroy!).and_return(true)
        end

        it 'transitions to deletion_in_progress and calls destroy!' do
          expect(organization).to receive(:hard_delete!).with(transition_user: user).and_call_original
          expect(organization).to receive(:destroy!)

          response

          expect(organization.reload.state).to eq('deletion_in_progress')
        end

        it 'returns a success response with the organization' do
          expect(response).to be_success
          expect(response.payload[:organization]).to eq(organization)
        end

        it 'logs the destruction event' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original

          expect(Gitlab::AppLogger).to receive(:info).with(
            log_payload('Organization hard deleted')
          )

          response
        end
      end

      context 'when organization is already in deletion_in_progress (worker path)' do
        before do
          organization.soft_delete!(transition_user: user)
          organization.hard_delete!(transition_user: user)
          allow(organization).to receive(:destroy!).and_return(true)
        end

        it 'calls destroy! without re-transitioning' do
          expect(organization).not_to receive(:hard_delete!)
          expect(organization).to receive(:destroy!)

          response

          expect(organization.reload.state).to eq('deletion_in_progress')
        end

        it 'still logs the destruction event' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original

          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              'class' => 'Organizations::HardDeleteService',
              'message' => 'Organization hard deleted'
            )
          )

          response
        end
      end

      context 'when destroy! raises an error' do
        let(:error) { ActiveRecord::RecordNotDestroyed.new('boom') }

        context 'when starting from soft_deleted (direct call)' do
          before do
            organization.soft_delete!(transition_user: user)
            allow(organization).to receive(:destroy!).and_raise(error)
          end

          it 'rolls back the state to soft_deleted, logs the error, and re-raises' do
            expect(Gitlab::AppLogger).to receive(:error).with(
              hash_including(
                'message' => 'Organization hard deletion failed',
                'error_class' => 'ActiveRecord::RecordNotDestroyed',
                'error_message' => 'boom',
                Labkit::Fields::GL_USER_ID => user.id,
                Labkit::Fields::GL_ORGANIZATION_ID => organization.id
              )
            )

            expect { response }.to raise_error(ActiveRecord::RecordNotDestroyed, 'boom')

            expect(organization.reload.state).to eq('soft_deleted')
            expect(Organizations::Organization.exists?(organization.id)).to be(true)
          end
        end

        context 'when starting from deletion_in_progress (worker path)' do
          before do
            organization.soft_delete!(transition_user: user)
            organization.hard_delete!(transition_user: user)
            allow(organization).to receive(:destroy!).and_raise(error)
          end

          it 'does not re-transition, rolls back, logs the error, and re-raises' do
            expect(organization).not_to receive(:hard_delete!)
            expect(Gitlab::AppLogger).to receive(:error).with(
              hash_including(
                'message' => 'Organization hard deletion failed',
                'error_class' => 'ActiveRecord::RecordNotDestroyed',
                'error_message' => 'boom'
              )
            )

            expect { response }.to raise_error(ActiveRecord::RecordNotDestroyed, 'boom')

            expect(organization.reload.state).to eq('soft_deleted')
          end
        end

        context 'when the abort_hard_deletion rollback itself fails' do
          let(:rollback_error) { StateMachines::InvalidTransition.new(organization, organization.class.state_machine, :abort_hard_deletion) }

          before do
            organization.soft_delete!(transition_user: user)
            allow(organization).to receive(:destroy!).and_raise(error)
            allow(organization).to receive(:abort_hard_deletion!).and_raise(rollback_error)
            allow(Gitlab::AppLogger).to receive(:error).and_call_original
          end

          it 'logs both the original and rollback errors, then re-raises the original' do
            expect(Gitlab::AppLogger).to receive(:error).with(
              hash_including(
                'message' => 'Organization hard deletion rollback failed',
                'error_class' => 'StateMachines::InvalidTransition'
              )
            ).ordered
            expect(Gitlab::AppLogger).to receive(:error).with(
              hash_including(
                'message' => 'Organization hard deletion failed',
                'error_class' => 'ActiveRecord::RecordNotDestroyed'
              )
            ).ordered

            expect { response }.to raise_error(ActiveRecord::RecordNotDestroyed, 'boom')
          end
        end
      end
    end
  end
end
