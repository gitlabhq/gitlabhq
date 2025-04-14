# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildCancelService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'develop') }

  describe '#execute' do
    subject(:execute) { described_class.new(build, user).execute }

    context 'when user is authorized to cancel the build' do
      before do
        project.add_developer(user)
      end

      context 'when build is cancelable' do
        let!(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

        it 'transits build to canceled', :aggregate_failures do
          response = execute

          expect(response).to be_success
          expect(response.payload.reload).to be_canceled
        end
      end

      context 'when build is not cancelable' do
        let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

        it 'responds with unprocessable entity', :aggregate_failures do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end
      end

      context 'when build is force cancelable' do
        let!(:build) { create(:ci_build, :canceling, pipeline: pipeline) }

        it 'responds to default request with unprocessable entity', :aggregate_failures do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end

        context 'for a force_cancel request' do
          let(:force_execute) { described_class.new(build, user, true).execute }

          context 'as a developer on the project' do
            it 'responds with unprocessable entity', :aggregate_failures do
              response = force_execute

              expect(response).to be_error
              expect(response.http_status).to eq(:unprocessable_entity)
            end
          end

          context 'as a maintainer on the project' do
            before do
              project.add_maintainer(user)
            end

            it 'transits build to canceled', :aggregate_failures do
              response = force_execute

              expect(response).to be_success
              expect(response.payload.reload).to be_canceled
            end
          end
        end
      end
    end

    context 'when user is not authorized to cancel the build' do
      let!(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

      it 'responds with forbidden', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:forbidden)
      end
    end
  end
end
