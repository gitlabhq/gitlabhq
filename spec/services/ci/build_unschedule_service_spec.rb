# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildUnscheduleService, :aggregate_failures, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, created_at: 1.day.ago) }

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

        context 'when the pipeline is archived' do
          before do
            stub_application_setting(archive_builds_in_seconds: 3600)
          end

          it 'responds with forbidden' do
            response = execute

            expect(response).to be_error
            expect(response.http_status).to eq(:forbidden)
          end
        end
      end

      context 'when build is not scheduled' do
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        it 'responds with unprocessable entity' do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end
      end
    end

    context 'when user is not authorized to unschedule the build' do
      let!(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'responds with forbidden' do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:forbidden)
      end
    end
  end
end
