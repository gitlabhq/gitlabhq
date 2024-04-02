# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::FreezePeriods, :aggregate_failures, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let(:api_user) { user }
  let(:invalid_cron) { '0 0 0 * *' }
  let(:last_freeze_period) { project.freeze_periods.last }

  describe 'GET /projects/:id/freeze_periods' do
    let(:path) { "/projects/#{project.id}/freeze_periods" }

    it_behaves_like 'GET request permissions for admin mode' do
      let!(:freeze_period) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }
      let(:failed_status_code) { :not_found }
    end

    context 'when the user is the admin' do
      let!(:freeze_period) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }

      it 'returns 200 HTTP status' do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the user is the maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'when there are two freeze_periods' do
        let!(:freeze_period_1) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }
        let!(:freeze_period_2) { create(:ci_freeze_period, project: project, created_at: 1.day.ago) }

        it 'returns 200 HTTP status' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns freeze_periods ordered by created_at ascending' do
          get api(path, user)

          expect(json_response.count).to eq(2)
          expect(freeze_period_ids).to eq([freeze_period_1.id, freeze_period_2.id])
        end

        it 'matches response schema' do
          get api(path, user)

          expect(response).to match_response_schema('public_api/v4/freeze_periods')
        end
      end

      context 'when there are no freeze_periods' do
        it 'returns 200 HTTP status' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns an empty response' do
          get api(path, user)

          expect(json_response).to be_empty
        end
      end
    end

    context 'when user is a guest' do
      before do
        project.add_guest(user)
      end

      let!(:freeze_period) do
        create(:ci_freeze_period, project: project)
      end

      it 'responds 403 Forbidden' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'responds 404 Not Found' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'responds 403 Forbidden' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GET /projects/:id/freeze_periods/:freeze_period_id' do
    let(:path) { "/projects/#{project.id}/freeze_periods/#{freeze_period.id}" }

    it_behaves_like 'GET request permissions for admin mode' do
      let!(:freeze_period) do
        create(:ci_freeze_period, project: project)
      end

      let(:failed_status_code) { :not_found }
    end

    context 'when there is a freeze period' do
      let!(:freeze_period) do
        create(:ci_freeze_period, project: project)
      end

      context 'when the user is the admin' do
        let!(:freeze_period) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }

        it 'responds 200 OK' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the user is the maintainer' do
        before do
          project.add_maintainer(user)
        end

        it 'responds 200 OK' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns a freeze period' do
          get api(path, user)

          expect(json_response).to include(
            'id' => freeze_period.id,
            'freeze_start' => freeze_period.freeze_start,
            'freeze_end' => freeze_period.freeze_end,
            'cron_timezone' => freeze_period.cron_timezone)
        end

        it 'matches response schema' do
          get api(path, user)

          expect(response).to match_response_schema('public_api/v4/freeze_period')
        end
      end

      context 'when user is a guest' do
        before do
          project.add_guest(user)
        end

        it 'responds 403 Forbidden' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'when project is public' do
          let(:project) { create(:project, :public) }

          context 'when freeze_period exists' do
            it 'responds 403 Forbidden' do
              get api(path, user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when freeze_period does not exist' do
            it 'responds 403 Forbidden' do
              get api("/projects/#{project.id}/freeze_periods/0", user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end
    end
  end

  describe 'POST /projects/:id/freeze_periods' do
    let(:params) do
      {
        freeze_start: '0 23 * * 5',
        freeze_end: '0 7 * * 1',
        cron_timezone: 'UTC'
      }
    end

    let(:path) { "/projects/#{project.id}/freeze_periods" }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    subject do
      post api(path, api_user, admin_mode: api_user.admin?), params: params
    end

    context 'when the user is the admin' do
      let(:api_user) { admin }

      it 'accepts the request' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when user is the maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'with valid params' do
        it 'accepts the request' do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'creates a new freeze period' do
          expect do
            subject
          end.to change { Ci::FreezePeriod.count }.by(1)

          expect(last_freeze_period.freeze_start).to eq('0 23 * * 5')
          expect(last_freeze_period.freeze_end).to eq('0 7 * * 1')
          expect(last_freeze_period.cron_timezone).to eq('UTC')
        end

        it 'matches response schema' do
          subject

          expect(response).to match_response_schema('public_api/v4/freeze_period')
        end
      end

      context 'with incomplete params' do
        let(:params) do
          {
            freeze_start: '0 23 * * 5',
            cron_timezone: 'UTC'
          }
        end

        it 'responds 400 Bad Request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq("freeze_end is missing")
        end
      end

      context 'with invalid params' do
        let(:params) do
          {
            freeze_start: '0 23 * * 5',
            freeze_end: invalid_cron,
            cron_timezone: 'UTC'
          }
        end

        it 'responds 400 Bad Request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['freeze_end']).to eq(['syntax is invalid'])
        end
      end
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it 'responds 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it 'responds 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'responds 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'responds 403 Forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'PUT /projects/:id/freeze_periods/:freeze_period_id' do
    let(:params) { { freeze_start: '0 22 * * 5', freeze_end: '5 4 * * sun' } }
    let!(:freeze_period) { create :ci_freeze_period, project: project }

    subject do
      put api("/projects/#{project.id}/freeze_periods/#{freeze_period.id}", api_user, admin_mode: api_user.admin?),
        params: params
    end

    context 'when user is the admin' do
      let(:api_user) { admin }

      it 'accepts the request' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user is the maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'with valid params' do
        it 'accepts the request' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'performs the update' do
          subject

          freeze_period.reload

          expect(freeze_period.freeze_start).to eq(params[:freeze_start])
          expect(freeze_period.freeze_end).to eq(params[:freeze_end])
        end

        it 'matches response schema' do
          subject

          expect(response).to match_response_schema('public_api/v4/freeze_period')
        end
      end

      context 'with invalid params' do
        let(:params) { { freeze_start: invalid_cron } }

        it 'responds 400 Bad Request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['freeze_start']).to eq(['syntax is invalid'])
        end
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it 'responds 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'responds 404 Not Found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'responds 403 Forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/freeze_periods/:freeze_period_id' do
    let!(:freeze_period) { create :ci_freeze_period, project: project }
    let(:freeze_period_id) { freeze_period.id }

    subject do
      delete api("/projects/#{project.id}/freeze_periods/#{freeze_period_id}", api_user, admin_mode: api_user.admin?)
    end

    context 'when user is the admin' do
      let(:api_user) { admin }

      it 'accepts the request' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when user is the maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'accepts the request' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'destroys the freeze period' do
        expect do
          subject
        end.to change { Ci::FreezePeriod.count }.by(-1)
      end

      context 'when it is a non-existing freeze period id' do
        let(:freeze_period_id) { 0 }

        it '404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it 'responds 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is not a project member' do
      it 'responds 404 Not Found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'responds 403 Forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  def freeze_period_ids
    json_response.map do |freeze_period_hash|
      freeze_period_hash.fetch('id')&.to_i
    end
  end
end
