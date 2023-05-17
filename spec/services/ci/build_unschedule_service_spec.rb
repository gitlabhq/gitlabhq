# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildUnscheduleService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(build, user).execute }

    context 'when user is authorized to unschedule the build' do
      before do
        project.add_maintainer(user)
      end

      context 'when build is scheduled' do
        let!(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

        it 'transits build to manual' do
          response = execute

          expect(response).to be_success
          expect(response.payload.reload).to be_manual
        end
      end

      context 'when build is not scheduled' do
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        it 'responds with unprocessable entity', :aggregate_failures do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end
      end
    end

    context 'when user is not authorized to unschedule the build' do
      let!(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'responds with forbidden', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:forbidden)
      end
    end
  end
end
