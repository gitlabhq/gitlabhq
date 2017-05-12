require 'spec_helper'

describe API::PipelineSchedules do
  set(:developer) { create(:user) }
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  before do
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/pipeline_schedules' do
    context 'authenticated user with valid permissions' do
      before do
        create(:ci_pipeline_schedule, project: project, owner: developer)
          .tap do |pipeline_schedule|
          pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
        end
      end

      it 'returns list of pipeline_schedules' do
        get api("/projects/#{project.id}/pipeline_schedules", developer)

        expect(response).to have_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('pipeline_schedules')
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
        .tap do |pipeline_schedule|
        pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
      end
    end

    context 'authenticated user with valid permissions' do
      it 'returns pipeline_schedule details' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer)

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
      end

      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        get api("/projects/#{project.id}/pipeline_schedules/-5", developer)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules' do
    let(:params) do
      attributes_for(:ci_pipeline_schedule,
        description: 'description', ref: 'master', cron: '* * * * *',
        cron_timezone: 'UTC', active: true)
    end

    context 'authenticated user with valid permissions' do
      context 'with required parameters' do
        it 'creates pipeline_schedule' do
          expect do
            post api("/projects/#{project.id}/pipeline_schedules", developer),
              params
          end
          .to change{project.pipeline_schedules.count}.by(1)

          expect(response).to have_http_status(:created)
          expect(response).to match_response_schema('pipeline_schedule')
          expect(json_response['description']).to eq(params[:description])
          expect(json_response['ref']).to eq(params[:ref])
          expect(json_response['cron']).to eq(params[:cron])
          expect(json_response['cron_timezone']).to eq(params[:cron_timezone])
          expect(json_response['active']).to eq(params[:active])
        end
      end

      context 'without required parameters' do
        it 'does not create pipeline_schedule' do
          post api("/projects/#{project.id}/pipeline_schedules", developer)

          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when cron has validation error' do
        it 'does not create pipeline_schedule' do
          post api("/projects/#{project.id}/pipeline_schedules", developer),
            params.tap { |_| params['cron'] = 'invalid-cron' }

          expect(response).to have_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create pipeline_schedule' do
        post api("/projects/#{project.id}/pipeline_schedules", user), params

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not create pipeline_schedule' do
        post api("/projects/#{project.id}/pipeline_schedules"), params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    context 'authenticated user with valid permissions' do
      it 'updates cron' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer),
          cron: '1 2 3 4 *'
        pipeline_schedule.reload

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
        expect(json_response['cron']).to eq('1 2 3 4 *')
        expect(pipeline_schedule.next_run_at.min).to eq(1)
        expect(pipeline_schedule.next_run_at.hour).to eq(2)
        expect(pipeline_schedule.next_run_at.day).to eq(3)
        expect(pipeline_schedule.next_run_at.month).to eq(4)
      end

      context 'when cron has validation error' do
        it 'does not update pipeline_schedule' do
          put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer),
            cron: 'invalid-cron'

          expect(response).to have_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update pipeline_schedule' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not update pipeline_schedule' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    context 'authenticated user with valid permissions' do
      let(:developer2) { create(:user) }

      before do
        project.add_developer(developer2)
      end

      it 'updates owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership", developer2)
        pipeline_schedule.reload

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
        expect(pipeline_schedule.owner).to eq(developer2)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not update owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:master) { create(:user) }

    let!(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    before do
      project.add_master(master)
    end

    context 'authenticated user with valid permissions' do
      it 'deletes pipeline_schedule' do
        expect do
          delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", master)
        end.to change{project.pipeline_schedules.count}.by(-1)

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
      end

      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/-5", master)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
