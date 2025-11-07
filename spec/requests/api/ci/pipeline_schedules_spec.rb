# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::PipelineSchedules, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project, :repository, public_builds: false) }

  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:project_owner) { create(:user, owner_of: project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/pipeline_schedules' do
    let(:url) { "/projects/#{project.id}/pipeline_schedules" }

    context 'authenticated user with valid permissions' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }

      before do
        pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
      end

      def create_pipeline_schedules(count)
        create_list(:ci_pipeline_schedule, count, project: project)
          .each do |pipeline_schedule|
          create(:user).tap do |user|
            project.add_developer(user)
            pipeline_schedule.update!(owner: user)
          end
          pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
        end
      end

      it 'returns list of pipeline_schedules' do
        get api(url, developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('pipeline_schedules')
      end

      it 'avoids N + 1 queries' do
        # We need at least two users to trigger a preload for that relation.
        create_pipeline_schedules(1)

        control = ActiveRecord::QueryRecorder.new do
          get api(url, developer)
        end

        create_pipeline_schedules(5)

        expect do
          get api(url, developer)
        end.not_to exceed_query_limit(control)
      end

      %w[active inactive].each do |target|
        context "when scope is #{target}" do
          before do
            create(:ci_pipeline_schedule, project: project, active: active?(target))
          end

          it 'returns matched pipeline schedules' do
            get api(url, developer), params: { scope: target }

            expect(json_response.map { |r| r['active'] }).to all(eq(active?(target)))
          end
        end

        def active?(str)
          str == 'active'
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return pipeline_schedules list' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not return pipeline_schedules list' do
        get api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :read_pipeline_schedule do
      let(:user) { maintainer }
      let(:boundary_object) { project }
      let(:request) { get api(url, personal_access_token: pat) }
    end
  end

  describe 'GET /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }
    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}" }

    before do
      pipeline_schedule.variables << build(:ci_pipeline_schedule_variable)
      pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
    end

    matcher :return_pipeline_schedule_successfully do
      match_unless_raises do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
      end
    end

    shared_context 'request with project permissions' do
      context 'authenticated user with project permisions' do
        before do
          project.add_maintainer(user)
        end

        it 'returns pipeline_schedule details' do
          get api(url, user)

          expect(response).to return_pipeline_schedule_successfully
          expect(json_response).to have_key('variables')
        end
      end
    end

    shared_examples 'request with schedule ownership' do
      context 'authenticated user with pipeline schedule ownership' do
        it 'returns pipeline_schedule details' do
          get api(url, developer)

          expect(response).to return_pipeline_schedule_successfully
          expect(json_response).to have_key('variables')
        end
      end
    end

    shared_examples 'request with unauthenticated user' do
      context 'with unauthenticated user' do
        it 'does not return pipeline_schedule' do
          get api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    shared_examples 'request with non-existing pipeline_schedule' do
      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        get api("/projects/#{project.id}/pipeline_schedules/-5", developer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with private project' do
      it_behaves_like 'request with schedule ownership'
      it_behaves_like 'request with project permissions'
      it_behaves_like 'request with unauthenticated user'
      it_behaves_like 'request with non-existing pipeline_schedule'

      context 'authenticated user with no project permissions' do
        it 'does not return pipeline_schedule' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'authenticated user with insufficient project permissions' do
        before do
          project.add_guest(user)
        end

        it 'does not return pipeline_schedule' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'authorizing granular token permissions', :read_pipeline_schedule do
        let(:user) { maintainer }
        let(:boundary_object) { project }
        let(:request) { get api(url, personal_access_token: pat) }
      end
    end

    context 'with public project' do
      let_it_be(:project) { create(:project, :repository, :public, public_builds: true) }

      it_behaves_like 'request with schedule ownership'
      it_behaves_like 'request with project permissions'
      it_behaves_like 'request with unauthenticated user'
      it_behaves_like 'request with non-existing pipeline_schedule'

      context 'authenticated user with no project permissions' do
        it 'returns pipeline_schedule with no variables' do
          get api(url, user)

          expect(response).to return_pipeline_schedule_successfully
          expect(json_response).not_to have_key('variables')
        end
      end

      context 'authenticated user with insufficient project permissions' do
        before do
          project.add_guest(user)
        end

        it 'returns pipeline_schedule with no variables' do
          get api(url, user)

          expect(response).to return_pipeline_schedule_successfully
          expect(json_response).not_to have_key('variables')
        end
      end

      context 'when public pipelines are disabled' do
        let_it_be(:project) { create(:project, :repository, :public, public_builds: false) }

        context 'authenticated user with no project permissions' do
          it 'does not return pipeline_schedule' do
            get api(url, user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'authenticated user with insufficient project permissions' do
          before do
            project.add_guest(user)
          end

          it 'returns pipeline_schedule with no variables' do
            get api(url, user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/pipelines' do
    let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }
    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/pipelines" }
    let!(:pipelines) { create_list(:ci_pipeline, 2, project: project, pipeline_schedule: pipeline_schedule, source: :schedule) }

    matcher :return_pipeline_schedule_pipelines_successfully do
      match_unless_raises do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/pipelines')
      end
    end

    shared_examples 'request with project permissions' do
      context 'authenticated user with project permissions' do
        before do
          project.add_maintainer(user)
        end

        it 'returns the details of pipelines triggered from the pipeline schedule' do
          get api(url, user)

          expect(response).to return_pipeline_schedule_pipelines_successfully
        end

        context 'when sorting' do
          it 'allows to sort pipelines ascending' do
            get api("#{url}?sort=asc", user)

            expect(response.parsed_body.map { |schedule| schedule['id'] }).to eq([pipelines.first.id, pipelines.last.id])
          end

          it 'allows to sort pipelines descending' do
            get api("#{url}?sort=desc", user)

            expect(response.parsed_body.map { |schedule| schedule['id'] }).to eq([pipelines.last.id, pipelines.first.id])
          end
        end
      end
    end

    shared_examples 'request with schedule ownership' do
      context 'authenticated user with pipeline schedule ownership' do
        it 'returns the details of pipelines triggered from the pipeline schedule' do
          get api(url, developer)

          expect(response).to return_pipeline_schedule_pipelines_successfully
        end
      end
    end

    shared_examples 'request with unauthenticated user' do
      context 'with unauthenticated user' do
        it 'does not return the details of pipelines triggered from the pipeline schedule' do
          get api(url)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    shared_examples 'request with non-existing pipeline_schedule' do
      it "responds with 404 Not Found if requesting for a non-existing pipeline schedule's pipelines" do
        get api("/projects/#{project.id}/pipeline_schedules/#{non_existing_record_id}/pipelines", developer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with private project' do
      it_behaves_like 'request with schedule ownership'
      it_behaves_like 'request with project permissions'
      it_behaves_like 'request with unauthenticated user'
      it_behaves_like 'request with non-existing pipeline_schedule'

      context 'authenticated user with no project permissions' do
        it 'does not return the details of pipelines triggered from the pipeline schedule' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'authenticated user with insufficient project permissions' do
        before do
          project.add_guest(user)
        end

        it 'does not return the details of pipelines triggered from the pipeline schedule' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'authorizing granular token permissions', [:read_pipeline_schedule, :read_pipeline] do
        let(:boundary_object) { project }
        let(:user) { maintainer }
        let(:request) { get api(url, personal_access_token: pat) }
      end
    end

    context 'with public project' do
      let_it_be(:project) { create(:project, :repository, :public, public_builds: true) }

      it_behaves_like 'request with schedule ownership'
      it_behaves_like 'request with project permissions'
      it_behaves_like 'request with unauthenticated user'
      it_behaves_like 'request with non-existing pipeline_schedule'

      context 'authenticated user with no project permissions' do
        it 'returns the details of pipelines triggered from the pipeline schedule' do
          get api(url, user)

          expect(response).to return_pipeline_schedule_pipelines_successfully
        end
      end

      context 'when public pipelines are disabled' do
        let_it_be(:project) { create(:project, :repository, :public, public_builds: false) }

        context 'authenticated user with no project permissions' do
          it 'does not return the details of pipelines triggered from the pipeline schedule' do
            get api(url, user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules' do
    let(:params) { attributes_for(:ci_pipeline_schedule) }
    let(:url) { "/projects/#{project.id}/pipeline_schedules" }

    context 'authenticated user with valid permissions' do
      context 'with required parameters' do
        it 'creates pipeline_schedule' do
          expect do
            post api(url, developer), params: params
          end.to change { project.pipeline_schedules.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('pipeline_schedule')
          expect(json_response['description']).to eq(params[:description])
          expect(json_response['ref']).to eq(params[:ref])
          expect(json_response['cron']).to eq(params[:cron])
          expect(json_response['cron_timezone']).to eq(params[:cron_timezone])
          expect(json_response['owner']['id']).to eq(developer.id)
        end
      end

      context 'without required parameters' do
        it 'does not create pipeline_schedule' do
          post api(url, developer)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when cron has validation error' do
        it 'does not create pipeline_schedule' do
          post api(url, developer),
            params: params.merge('cron' => 'invalid-cron')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end

      context 'with inputs' do
        let(:input_params) do
          attributes_for(:ci_pipeline_schedule).merge(
            inputs: [
              { name: 'STRING_INPUT', value: 'string value' },
              { name: 'BOOL_INPUT', value: true },
              { name: 'NUMBER_INPUT', value: 42 },
              { name: 'ARRAY_INPUT', value: %w[one two three] },
              { name: 'COMPLEX_ARRAY', value: [{ foo: 1 }, { bar: 2 }] }
            ]
          )
        end

        it 'creates pipeline_schedule with inputs' do
          expect do
            post api(url, developer), params: input_params
          end.to change { project.pipeline_schedules.count }.by(1)
             .and change { Ci::PipelineScheduleInput.count }.by(5)

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('pipeline_schedule')

          schedule = Ci::PipelineSchedule.last
          expect(schedule.inputs.count).to eq(5)
          expect(schedule.inputs.find_by(name: 'BOOL_INPUT').value).to be_truthy
          expect(schedule.inputs.find_by(name: 'NUMBER_INPUT').value).to eq('42')
          expect(schedule.inputs.find_by(name: 'ARRAY_INPUT').value).to match_array(%w[one two three])
          expect(schedule.inputs.find_by(name: 'COMPLEX_ARRAY').value).to match_array([{ 'foo' => '1', 'bar' => '2' }])
        end
      end

      context 'when ref has validation error' do
        it 'does not create pipeline_schedule' do
          post api(url, developer),
            params: params.merge('ref' => 'invalid-ref')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to have_key('ref')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create pipeline_schedule' do
        post api(url, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not create pipeline_schedule' do
        post api(url), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :create_pipeline_schedule do
      let(:boundary_object) { project }
      let(:user) { maintainer }
      let(:request) { post api(url, personal_access_token: pat), params: params }
    end
  end

  describe 'PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}" }

    context 'authenticated user with valid permissions' do
      it 'updates cron' do
        put api(url, developer), params: { cron: '1 2 3 4 *' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
        expect(json_response['cron']).to eq('1 2 3 4 *')
      end

      context 'with inputs' do
        let!(:pipeline_schedule_input) do
          create(:ci_pipeline_schedule_input,
            name: 'EXISTING_INPUT',
            value: 'old_value',
            pipeline_schedule: pipeline_schedule)
        end

        it 'adds a new input' do
          expect do
            put api(url, developer),
              params: { inputs: [{ name: 'NEW_INPUT', value: 'new_value' }] }
          end.to change { pipeline_schedule.inputs.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(pipeline_schedule.inputs.find_by(name: 'NEW_INPUT').value).to eq('new_value')
        end

        it 'updates an existing input' do
          expect do
            put api(url, developer),
              params: { inputs: [{ name: 'EXISTING_INPUT', value: 'updated_value' }] }
          end.not_to change { pipeline_schedule.inputs.count }

          expect(response).to have_gitlab_http_status(:ok)
          expect(pipeline_schedule.inputs.find_by(name: 'EXISTING_INPUT').value).to eq('updated_value')
        end

        it 'deletes an existing input' do
          expect do
            put api(url, developer),
              params: { inputs: [{ name: 'EXISTING_INPUT', destroy: true }] }
          end.to change { pipeline_schedule.inputs.count }.by(-1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(pipeline_schedule.inputs.find_by(name: 'EXISTING_INPUT')).to be_nil
        end

        it 'performs multiple operations at once' do
          expect do
            put api(url, developer),
              params: {
                inputs: [
                  { name: 'EXISTING_INPUT', value: 'updated_value' },
                  { name: 'NEW_INPUT', value: 'brand_new' },
                  { name: 'TO_DELETE', value: 'anything', destroy: true }
                ]
              }
          end.to change { pipeline_schedule.inputs.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(pipeline_schedule.inputs.find_by(name: 'EXISTING_INPUT').value).to eq('updated_value')
          expect(pipeline_schedule.inputs.find_by(name: 'NEW_INPUT').value).to eq('brand_new')
        end
      end

      context 'when cron has validation error' do
        it 'does not update pipeline_schedule' do
          put api(url, developer),
            params: { cron: 'invalid-cron' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end

      context 'when ref has validation error' do
        it 'does not update pipeline_schedule' do
          put api(url, developer),
            params: { ref: 'invalid-ref' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to have_key('ref')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      context 'as a project maintainer' do
        before do
          project.add_maintainer(user)
        end

        it 'does not update pipeline_schedule' do
          put api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'as a project owner' do
        before do
          project.add_owner(user)
        end

        it 'does not update pipeline_schedule' do
          put api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with no special role' do
        it 'does not update pipeline_schedule' do
          put api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'unauthenticated user' do
      it 'does not update pipeline_schedule' do
        put api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :update_pipeline_schedule do
      let(:boundary_object) { project }
      let(:user) { developer }
      let(:request) { put api(url, personal_access_token: pat), params: { cron: '1 2 3 4 *' } }
    end
  end

  describe 'POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership" }

    context 'as an authenticated user with valid permissions' do
      it 'updates owner' do
        expect { post api(url, maintainer) }
          .to change { pipeline_schedule.reload.owner }.from(developer).to(maintainer)

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('pipeline_schedule')
      end
    end

    context 'as an authenticated user with invalid permissions' do
      it 'does not update owner' do
        post api(url, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an unauthenticated user' do
      it 'does not update owner' do
        post api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'as the existing owner of the schedule' do
      it 'accepts the request and leaves the schedule unchanged' do
        expect do
          post api(url, developer)
        end.not_to change { pipeline_schedule.reload.owner }

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :own_pipeline_schedule do
      let(:boundary_object) { project }
      let(:user) { maintainer }
      let(:request) { post api(url, personal_access_token: pat) }
    end
  end

  describe 'DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let_it_be_with_reload(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }

    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}" }

    context 'authenticated user with valid permissions' do
      it 'deletes pipeline_schedule' do
        expect do
          delete api(url, maintainer)
        end.to change { project.pipeline_schedules.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/-5", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:request) { api(url, maintainer) }
      end
    end

    context 'authenticated user with invalid permissions' do
      let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: maintainer) }

      it 'does not delete pipeline_schedule' do
        delete api(url, developer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete pipeline_schedule' do
        delete api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :delete_pipeline_schedule do
      let(:boundary_object) { project }
      let(:user) { maintainer }
      let(:request) { delete api(url, personal_access_token: pat) }
    end
  end

  describe 'POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play' do
    let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/play" }

    context 'authenticated user with `:play_pipeline_schedule` permission' do
      it 'schedules a pipeline worker' do
        expect(RunPipelineScheduleWorker)
          .to receive(:perform_async)
          .with(pipeline_schedule.id, developer.id)
          .and_call_original

        post api(url, developer)

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'renders an error if scheduling failed' do
        expect(RunPipelineScheduleWorker)
          .to receive(:perform_async)
          .with(pipeline_schedule.id, developer.id)
          .and_return(nil)

        post api(url, developer)

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end

    context 'authenticated user with insufficient access' do
      before do
        project.add_guest(user)
      end

      it 'responds with not found' do
        post api(url, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'responds with unauthorized' do
        post api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with sidekiq inline processing', :sidekiq_might_not_need_inline do
      it_behaves_like 'authorizing granular token permissions', :play_pipeline_schedule do
        let(:boundary_object) { project }
        let(:user) { developer }
        let(:request) { post api(url, personal_access_token: pat) }
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables' do
    let(:params) { attributes_for(:ci_pipeline_schedule_variable) }

    let_it_be(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    let(:url) { "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/variables" }

    context 'authenticated user with valid permissions' do
      context 'with required parameters' do
        let(:pipeline_schedule) do
          create(:ci_pipeline_schedule, project: project, owner: api_user)
        end

        shared_examples 'creates pipeline_schedule_variables' do
          it do
            expect do
              post api(url, api_user),
                params: params.merge(variable_type: 'file')
            end.to change { pipeline_schedule.variables.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
            expect(response).to match_response_schema('pipeline_schedule_variable')
            expect(json_response['key']).to eq(params[:key])
            expect(json_response['value']).to eq(params[:value])
            expect(json_response['variable_type']).to eq('file')
          end
        end

        shared_examples 'fails to create pipeline_schedule_variables' do
          it do
            post api(url, api_user),
              params: params.merge(variable_type: 'file')

            expect(pipeline_schedule.variables.count).to eq(0)
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when project restricts use of user defined variables' do
          before do
            project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
          end

          context 'as developer' do
            let(:api_user) { developer }

            it_behaves_like 'fails to create pipeline_schedule_variables'
          end

          context 'as maintainer' do
            let(:api_user) { maintainer }

            it_behaves_like 'creates pipeline_schedule_variables'
          end

          context 'as owner' do
            let(:api_user) { project_owner }

            it_behaves_like 'creates pipeline_schedule_variables'
          end
        end

        context 'when project does not restrict use of user defined variables' do
          before do
            project.update!(ci_pipeline_variables_minimum_override_role: :developer)
          end

          context 'as developer' do
            let(:api_user) { developer }

            it_behaves_like 'creates pipeline_schedule_variables'
          end

          context 'as maintainer' do
            let(:api_user) { maintainer }

            it_behaves_like 'creates pipeline_schedule_variables'
          end

          context 'as owner' do
            let(:api_user) { project_owner }

            it_behaves_like 'creates pipeline_schedule_variables'
          end
        end
      end

      context 'without required parameters' do
        it 'does not create pipeline_schedule_variable' do
          post api(url, developer)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when key has validation error' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :developer)
        end

        it 'does not create pipeline_schedule_variable' do
          post api(url, developer),
            params: params.merge('key' => '!?!?')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to have_key('key')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create pipeline_schedule_variable' do
        post api(url, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not create pipeline_schedule_variable' do
        post api(url), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :create_pipeline_schedule_variable do
      let(:boundary_object) { project }
      let(:user) { developer }
      let(:request) { post api(url, personal_access_token: pat), params: params }
    end
  end

  describe 'PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
    let_it_be(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    let(:pipeline_schedule_variable) do
      create(:ci_pipeline_schedule_variable, pipeline_schedule: pipeline_schedule)
    end

    let(:url) do
      "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/variables/#{pipeline_schedule_variable.key}"
    end

    let(:params) { { value: 'updated_value', variable_type: 'file' } }

    context 'authenticated user with valid permissions' do
      let(:pipeline_schedule) do
        create(:ci_pipeline_schedule, project: project, owner: api_user)
      end

      shared_examples 'updates pipeline_schedule_variable' do
        it do
          put api(url, api_user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('pipeline_schedule_variable')
          expect(json_response['value']).to eq('updated_value')
          expect(json_response['variable_type']).to eq('file')
        end
      end

      shared_examples 'fails to update pipeline_schedule_variable' do
        it do
          put api(url, api_user), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when project restricts use of user defined variables' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
        end

        context 'as developer' do
          let(:api_user) { developer }

          it_behaves_like 'fails to update pipeline_schedule_variable'
        end

        context 'as maintainer' do
          let(:api_user) { maintainer }

          it_behaves_like 'updates pipeline_schedule_variable'
        end

        context 'as owner' do
          let(:api_user) { project_owner }

          it_behaves_like 'updates pipeline_schedule_variable'
        end
      end

      context 'when project does not restrict use of user defined variables' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :developer)
        end

        context 'as developer' do
          let(:api_user) { developer }

          it_behaves_like 'updates pipeline_schedule_variable'
        end

        context 'as maintainer' do
          let(:api_user) { maintainer }

          it_behaves_like 'updates pipeline_schedule_variable'
        end

        context 'as owner' do
          let(:api_user) { project_owner }

          it_behaves_like 'updates pipeline_schedule_variable'
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update pipeline_schedule_variable' do
        put api(url, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not update pipeline_schedule_variable' do
        put api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :update_pipeline_schedule_variable do
      let(:boundary_object) { project }
      let(:user) { developer }
      let(:request) { put api(url, personal_access_token: pat), params: params }
    end
  end

  describe 'DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
    let_it_be(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    let_it_be_with_reload(:pipeline_schedule_variable) do
      create(:ci_pipeline_schedule_variable, pipeline_schedule: pipeline_schedule)
    end

    let(:url) do
      "/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/variables/#{pipeline_schedule_variable.key}"
    end

    context 'authenticated user with valid permissions' do
      shared_examples 'deletes pipeline_schedule_variable' do
        it do
          expect do
            delete api(url, api_user)
          end.to change { pipeline_schedule.variables.count }.by(-1)

          expect(response).to have_gitlab_http_status(:accepted)
          expect(response).to match_response_schema('pipeline_schedule_variable')
        end
      end

      shared_examples 'fails to delete pipeline_schedule_variable' do
        it do
          expect do
            delete api(url, api_user)
          end.not_to change { pipeline_schedule.variables.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when project restricts use of user defined variables' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
        end

        context 'as developer' do
          let(:api_user) { developer }

          it_behaves_like 'fails to delete pipeline_schedule_variable'
        end

        context 'as maintainer' do
          let(:api_user) { maintainer }

          it_behaves_like 'deletes pipeline_schedule_variable'
        end

        context 'as owner' do
          let(:api_user) { project_owner }

          it_behaves_like 'deletes pipeline_schedule_variable'
        end
      end

      context 'when project does not restrict use of user defined variables' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :developer)
        end

        context 'as developer' do
          let(:api_user) { developer }

          it_behaves_like 'deletes pipeline_schedule_variable'
        end

        context 'as maintainer' do
          let(:api_user) { maintainer }

          it_behaves_like 'deletes pipeline_schedule_variable'
        end

        context 'as owner' do
          let(:api_user) { project_owner }

          it_behaves_like 'deletes pipeline_schedule_variable'
        end
      end

      context 'as developer' do
        let(:api_user) { developer }

        it 'responds with 404 Not Found if requesting non-existing pipeline_schedule_variable' do
          delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/variables/____", maintainer)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: maintainer) }

      it 'does not delete pipeline_schedule_variable' do
        delete api(url, developer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete pipeline_schedule_variable' do
        delete api(url)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :delete_pipeline_schedule_variable do
      let(:boundary_object) { project }
      let(:user) { developer }
      let(:request) { delete api(url, personal_access_token: pat) }
    end
  end
end
