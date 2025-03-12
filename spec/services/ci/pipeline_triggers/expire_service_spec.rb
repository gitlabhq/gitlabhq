# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggers::ExpireService, :aggregate_failures, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let_it_be(:pipeline_trigger) { create(:ci_trigger, project: project) }

    subject(:execute) { described_class.new(user: current_user, trigger: pipeline_trigger).execute }

    context 'when user does not have permission' do
      before_all do
        project.add_developer(current_user)
      end

      it 'returns an error' do
        is_expected.to be_error.and have_attributes(
          message: 'The current user is not authorized to manage the pipeline trigger token',
          reason: :forbidden
        )
      end
    end

    context 'when user has permission' do
      before_all do
        project.add_maintainer(current_user)
      end

      it 'expires the pipeline trigger token' do
        expect { execute }.to change { pipeline_trigger.reload.expired? }.from(false).to(true)
        expect(execute).to be_success
      end

      context 'when update fails' do
        before do
          errors = ActiveModel::Errors.new(pipeline_trigger).tap { |e| e.add(:base, 'Some error') }
          allow(pipeline_trigger).to receive_messages(update: false, errors: errors)
        end

        it { is_expected.to be_error.and have_attributes(message: 'Some error') }
      end
    end
  end
end
