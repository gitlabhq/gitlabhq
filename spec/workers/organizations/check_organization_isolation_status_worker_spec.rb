# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::CheckOrganizationIsolationStatusWorker, feature_category: :organization do
  describe "#perform" do
    let_it_be_with_reload(:model) { create(:issue) }
    let(:duplicated_to_id) { non_existing_record_id }
    let(:changes) do
      {
        "duplicated_to_id" => [nil, duplicated_to_id]
      }
    end

    let(:job_args) { [model.class.name, model.id, changes] }

    subject(:worker) { described_class.new }

    context 'when the state of the record matches the changes argument' do
      let(:status_service) { instance_double(Gitlab::Organizations::IsolationStatus) }

      before do
        model.organization.mark_as_isolated!
      end

      context 'and the model has a single column as primary key' do
        let_it_be(:another_issue) { create(:issue) }
        let(:duplicated_to_id) { another_issue.id }

        before do
          model.update!(duplicated_to: another_issue)
        end

        it 'calls the service' do
          expect(
            Gitlab::Organizations::IsolationStatus
          ).to receive(:new).with(model, [:duplicated_to]).and_return(status_service)
          expect(status_service).to receive(:verify!)

          worker.perform(*job_args)
        end

        it_behaves_like 'an idempotent worker'
      end

      context 'when model_class starts with ::' do
        let_it_be(:third_issue) { create(:issue) }
        let(:duplicated_to_id) { third_issue.id }
        let(:job_args) { ["::#{model.class.name}", model.id, changes] }

        before do
          model.reload
          model.update!(duplicated_to: third_issue)
        end

        it 'calls the service' do
          expect(
            Gitlab::Organizations::IsolationStatus
          ).to receive(:new).with(model, [:duplicated_to]).and_return(status_service)
          expect(status_service).to receive(:verify!)

          worker.perform(*job_args)
        end
      end

      context 'and the model has a composite primary key' do
        let_it_be(:follower) { create(:user) }
        let_it_be(:followee) { create(:user) }
        let_it_be_with_reload(:model) { Users::UserFollowUser.create!(follower: follower, followee: followee) }
        let_it_be(:another_followee) { create(:user) }
        let(:changes) do
          {
            "followee_id" => [followee.id, another_followee.id]
          }
        end

        before do
          model.update!(followee: another_followee)
        end

        it 'calls the service' do
          expect(
            Gitlab::Organizations::IsolationStatus
          ).to receive(:new).with(model, [:followee]).and_return(status_service)
          expect(status_service).to receive(:verify!)

          worker.perform(*job_args)
        end
      end
    end

    context 'when the organization is not marked as isolated' do
      let_it_be(:another_issue) { create(:issue) }
      let(:duplicated_to_id) { another_issue.id }

      before do
        model.update!(duplicated_to: another_issue)
      end

      it 'does not call the service' do
        expect(::Gitlab::Organizations::IsolationStatus).not_to receive(:new)

        worker.perform(*job_args)
      end
    end

    context 'when the state of the record changed' do
      it "does not call the service" do
        expect(::Gitlab::Organizations::IsolationStatus).not_to receive(:new)

        worker.perform(*job_args)
      end
    end

    context 'when the model class is not an ActiveRecord model' do
      let(:job_args) { ["String", 1, changes] }

      it "does not call the service" do
        expect(::Gitlab::Organizations::IsolationStatus).not_to receive(:new)

        worker.perform(*job_args)
      end
    end

    context 'when the model class name is invalid' do
      let(:job_args) { ["Invalid-Class-Name", 1, changes] }

      it "does not call the service" do
        expect(::Gitlab::Organizations::IsolationStatus).not_to receive(:new)

        worker.perform(*job_args)
      end
    end

    context 'when the record does not exist' do
      let(:job_args) { [model.class.name, non_existing_record_id, changes] }

      it "does nothing" do
        expect(::Gitlab::Organizations::IsolationStatus).not_to receive(:new)

        worker.perform(*job_args)
      end
    end
  end
end
