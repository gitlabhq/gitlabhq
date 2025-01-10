# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersController, feature_category: :user_management do
  # This user should have the same e-mail address associated with the GPG key prepared for tests
  let(:user) { create(:user, email: GpgHelpers::User1.emails[0]) }
  let(:private_user) { create(:user, private_profile: true) }
  let(:public_user) { create(:user) }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  describe 'GET #show' do
    shared_examples_for 'renders the show template' do
      it 'renders the show template' do
        get user_url user.username

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
      end
    end

    context 'when the user exists and has public visibility' do
      context 'when logged in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders the show template'
      end

      context 'when logged out' do
        it_behaves_like 'renders the show template'
      end
    end

    context 'when public visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when logged out' do
        it 'redirects to login page' do
          get user_url user.username

          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders the show template'
      end
    end

    context 'when a user by that username does not exist' do
      context 'when logged out' do
        it 'redirects to login page' do
          get user_url 'nonexistent'

          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders 404' do
          get user_url 'nonexistent'

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'requested in json format' do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
        Gitlab::DataBuilder::Push.build_sample(project, user)

        sign_in(user)
      end

      it 'returns 404 with deprecation message' do
        # Requesting "/username?format=json" instead of "/username.json"
        get user_url user.username, params: { format: :json }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.media_type).to eq('application/json')
        expect(Gitlab::Json.parse(response.body)['message']).to include('This endpoint is deprecated.')
      end
    end
  end

  describe 'GET /users/:username (deprecated user top)' do
    it 'redirects to /user1' do
      get '/users/user1'

      expect(response).to redirect_to user_path('user1')
    end
  end

  describe 'GET #activity' do
    shared_examples_for 'renders the show template' do
      it 'renders the show template' do
        get user_activity_url user.username

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
      end
    end

    context 'when the user exists and has public visibility' do
      context 'when logged in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders the show template'
      end

      context 'when logged out' do
        it_behaves_like 'renders the show template'
      end
    end

    context 'when public visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when logged out' do
        it 'redirects to login page' do
          get user_activity_url user.username

          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders the show template'
      end
    end

    context 'when a user by that username does not exist' do
      context 'when logged out' do
        it 'redirects to login page' do
          get user_activity_url 'nonexistent'

          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders 404' do
          get user_activity_url 'nonexistent'

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'requested in json format' do
      context 'when profile_tabs_vue feature flag is turned OFF' do
        let(:project) { create(:project) }

        before do
          project.add_developer(user)
          Gitlab::DataBuilder::Push.build_sample(project, user)
          stub_feature_flags(profile_tabs_vue: false)
          sign_in(user)
        end

        it 'loads events' do
          get user_activity_url user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body)['count']).to eq(1)
        end

        it 'hides events if the user cannot read cross project' do
          allow(Ability).to receive(:allowed?).and_call_original
          expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

          get user_activity_url user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body)['count']).to eq(0)
        end

        it 'hides events if the user has a private profile' do
          Gitlab::DataBuilder::Push.build_sample(project, private_user)

          get user_activity_url private_user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body)['count']).to eq(0)
        end
      end

      context 'when profile_tabs_vue feature flag is turned ON' do
        let(:project) { create(:project) }

        before do
          project.add_developer(user)
          Gitlab::DataBuilder::Push.build_sample(project, user)
          stub_feature_flags(profile_tabs_vue: true)
          sign_in(user)
        end

        it 'loads events' do
          get user_activity_url user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body).count).to eq(1)
        end

        it 'hides events if the user cannot read cross project' do
          allow(Ability).to receive(:allowed?).and_call_original
          expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

          get user_activity_url user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body).count).to eq(0)
        end

        it 'hides events if the user has a private profile' do
          Gitlab::DataBuilder::Push.build_sample(project, private_user)

          get user_activity_url private_user.username, format: :json

          expect(response.media_type).to eq('application/json')
          expect(Gitlab::Json.parse(response.body).count).to eq(0)
        end

        it 'hides events if the user has a private profile' do
          project = create(:project, :private)
          private_event_user = create(:user, include_private_contributions: true)
          push_data = Gitlab::DataBuilder::Push.build_sample(project, private_event_user)
          EventCreateService.new.push(project, private_event_user, push_data)

          get user_activity_url private_event_user.username, format: :json

          response_body = Gitlab::Json.parse(response.body)
          event = response_body.first
          expect(response.media_type).to eq('application/json')
          expect(response_body.count).to eq(1)
          expect(event).to include('created_at', 'author', 'action')
          expect(event['action']).to eq('private')
          expect(event).not_to include('ref', 'commit', 'target', 'resource_parent')
        end
      end
    end
  end

  describe 'GET #ssh_keys' do
    context 'non existent user' do
      it 'does not generally work' do
        get '/not-existent.keys'

        expect(response).not_to be_successful
      end
    end

    context 'user with no keys' do
      it 'responds the empty body with text/plain content type' do
        get "/#{user.username}.keys"

        expect(response).to be_successful
        expect(response.media_type).to eq("text/plain")
        expect(response.body).to eq("")
      end
    end

    context 'user with keys' do
      let!(:key) { create(:key, user: user) }
      let!(:another_key) { create(:another_key, user: user) }
      let!(:deploy_key) { create(:deploy_key, user: user) }

      shared_examples_for 'renders all public keys' do
        it 'renders all non-deploy keys terminated with a new line with text/plain content type without the comment key' do
          get "/#{user.username}.keys"

          expect(response).to be_successful
          expect(response.media_type).to eq("text/plain")

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.all_ssh_keys.map { |key| key + "\n" }.join)

          expect(response.body).to include(key.key.sub(' dummy@gitlab.com', ''))
          expect(response.body).to include(another_key.key.sub(' dummy@gitlab.com', ''))

          expect(response.body).not_to match(/dummy@gitlab.com/)

          expect(response.body).not_to include(deploy_key.key)
        end
      end

      context 'while signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders all public keys'
      end

      context 'when logged out' do
        before do
          sign_out(user)
        end

        it_behaves_like 'renders all public keys'

        context 'when public visibility is restricted' do
          before do
            stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
          end

          it 'redirects to sign in' do
            get "/#{user.username}.keys"

            expect(response).to redirect_to(new_user_session_path)
          end
        end
      end
    end
  end

  describe 'GET #gpg_keys' do
    context 'non existent user' do
      it 'does not generally work' do
        get '/not-existent.keys'

        expect(response).not_to be_successful
      end
    end

    context 'user with no keys' do
      it 'responds the empty body with text/plain content type' do
        get "/#{user.username}.gpg"

        expect(response).to be_successful
        expect(response.media_type).to eq("text/plain")
        expect(response.body).to eq("")
      end
    end

    context 'user with keys' do
      let!(:gpg_key) { create(:gpg_key, user: user) }
      let!(:another_gpg_key) { create(:another_gpg_key, user: user.reload) }

      shared_examples_for 'renders all verified GPG keys' do
        it 'renders all verified keys terminated with a new line with text/plain content type' do
          get "/#{user.username}.gpg"

          expect(response).to be_successful

          expect(response.media_type).to eq("text/plain")

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.gpg_keys.filter_map { |gpg_key| gpg_key.key + "\n" if gpg_key.verified? }.join)

          expect(response.body).to include(gpg_key.key)
          expect(response.body).to include(another_gpg_key.key)
        end
      end

      context 'while signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'renders all verified GPG keys'
      end

      context 'when logged out' do
        before do
          sign_out(user)
        end

        it_behaves_like 'renders all verified GPG keys'
      end

      context 'when revoked' do
        shared_examples_for 'doesn\'t render revoked keys' do
          it 'doesn\'t render revoked keys' do
            get "/#{user.username}.gpg"

            expect(response.body).not_to eq('')

            expect(response.body).to include(gpg_key.key)
            expect(response.body).not_to include(another_gpg_key.key)
          end
        end

        before do
          sign_in(user)
          another_gpg_key.revoke
        end

        context 'while signed in' do
          it_behaves_like 'doesn\'t render revoked keys'
        end

        context 'when logged out' do
          before do
            sign_out(user)
          end

          it_behaves_like 'doesn\'t render revoked keys'
        end
      end
    end
  end

  describe 'GET #calendar' do
    context 'for user' do
      let(:project) { create(:project) }

      before do
        sign_in(user)
        project.add_developer(user)
      end

      context 'with public profile' do
        it 'renders calendar' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, public_user)
          EventCreateService.new.push(project, public_user, push_data)

          get user_calendar_url public_user.username, format: :json

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with private profile' do
        it 'does not render calendar' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, private_user)
          EventCreateService.new.push(project, private_user, push_data)

          get user_calendar_url private_user.username, format: :json

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'forked project' do
      let(:project) { create(:project) }
      let(:forked_project) { Projects::ForkService.new(project, user).execute[:project] }

      before do
        sign_in(user)
        project.add_developer(user)

        push_data = Gitlab::DataBuilder::Push.build_sample(project, user)

        fork_push_data = Gitlab::DataBuilder::Push
          .build_sample(forked_project, user)

        EventCreateService.new.push(project, user, push_data)
        EventCreateService.new.push(forked_project, user, fork_push_data)
      end

      it 'includes forked projects' do
        get user_calendar_url user.username

        expect(assigns(:contributions_calendar).projects.count).to eq(2)
      end
    end
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      allow_next_instance_of(User) do |instance|
        allow(instance).to receive(:contributed_projects_ids).and_return([project.id])
      end

      sign_in(user)
      project.add_developer(user)
    end

    it 'renders activities on the specified day' do
      get user_calendar_activities_url user.username, date: '2014-07-31'

      expect(response.media_type).to eq('text/html')
      expect(response.body).to include('Jul 31, 2014')
    end

    context 'for user' do
      context 'with public profile' do
        let(:issue) { create(:issue, project: project, author: user) }
        let(:note) { create(:note, noteable: issue, author: user, project: project) }

        before do
          create_push_event
          create_note_event
        end

        it 'renders calendar_activities' do
          get user_calendar_activities_url public_user.username

          expect(response.body).not_to be_empty
        end

        it 'renders the correct url for issues and work items' do
          work_item = create(:work_item, :task, project: project)
          issue = create(:issue, project: project)
          EventCreateService.new.open_issue(work_item, public_user)
          EventCreateService.new.open_issue(issue, public_user)

          get user_calendar_activities_url public_user.username

          expect(response.body).to include(project_work_item_path(project, work_item.iid))
          expect(response.body).to include(project_issue_path(project, issue))
        end

        it 'avoids N+1 queries', :request_store do
          get user_calendar_activities_url public_user.username

          control = ActiveRecord::QueryRecorder.new { get user_calendar_activities_url public_user.username }

          create_push_event
          create_note_event

          expect { get user_calendar_activities_url public_user.username }.not_to exceed_query_limit(control)
        end
      end

      context 'with private profile' do
        it 'does not render calendar_activities' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, private_user)
          EventCreateService.new.push(project, private_user, push_data)

          get user_calendar_activities_url private_user.username

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'external authorization' do
        subject { get user_calendar_activities_url user.username }

        it_behaves_like 'disabled when using an external authorization service'
      end

      def create_push_event
        push_data = Gitlab::DataBuilder::Push.build_sample(project, public_user)
        EventCreateService.new.push(project, public_user, push_data)
      end

      def create_note_event
        EventCreateService.new.leave_note(note, public_user)
      end
    end
  end

  describe 'GET #contributed' do
    let(:project) { create(:project, :public) }
    let(:aimed_for_deletion_project) { create(:project, :public, :archived, marked_for_deletion_at: 3.days.ago) }

    subject do
      get user_contributed_projects_url author.username, format: format
    end

    before do
      sign_in(user)

      project.add_developer(public_user)
      project.add_developer(private_user)
      aimed_for_deletion_project.add_developer(public_user)
      aimed_for_deletion_project.add_developer(private_user)
      create(:push_event, project: project, author: author)
      create(:push_event, project: aimed_for_deletion_project, author: author)
    end

    shared_examples_for 'renders contributed projects' do
      it 'renders contributed projects' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to be_empty
      end
    end

    %i[html json].each do |format|
      context "with format: #{format}" do
        let(:format) { format }

        before do
          subject
        end

        context 'with public profile' do
          let(:author) { public_user }

          it_behaves_like 'renders contributed projects'
        end

        context 'with private profile' do
          let(:author) { private_user }

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end

          context 'with a user that has the ability to read private profiles', :enable_admin_mode do
            let(:user) { create(:admin) }

            it_behaves_like 'renders contributed projects'

            if format == :json
              it 'does not list projects aimed for deletion' do
                expect(response).to have_gitlab_http_status(:ok)
                expect(response.body).not_to include aimed_for_deletion_project.name
              end
            end
          end
        end
      end
    end

    describe 'pagination' do
      let(:author) { public_user }
      let(:format) { :json }
      let(:per_page_limit) { 2 }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page_limit)

        create_list(:project, per_page_limit + 1, :public, :small_repo).each do |small_project|
          small_project.add_developer(author)
          create(:push_event, project: small_project, author: author)
        end

        subject
      end

      it_behaves_like 'renders contributed projects'

      it 'paginates without count' do
        expect(assigns(:contributed_projects).size).to eq(per_page_limit)
        expect(assigns(:contributed_projects)).to be_a(Kaminari::PaginatableWithoutCount)
      end
    end
  end

  describe 'GET #starred' do
    let(:project) { create(:project, :public) }
    let(:aimed_for_deletion_project) { create(:project, :public, :archived, marked_for_deletion_at: 3.days.ago) }

    subject do
      get user_starred_projects_url author.username, format: format
    end

    before do
      author.toggle_star(project)

      sign_in(user)
      subject
    end

    shared_examples_for 'renders starred projects' do
      it 'renders starred projects' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to be_empty
      end
    end

    %i[html json].each do |format|
      context "with format: #{format}" do
        let(:format) { format }

        context 'with public profile' do
          let(:author) { public_user }

          it_behaves_like 'renders starred projects'
        end

        context 'with private profile' do
          let(:author) { private_user }

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end

          context 'with a user that has the ability to read private profiles', :enable_admin_mode do
            let(:user) { create(:admin) }

            it_behaves_like 'renders starred projects'

            if format == :json
              it 'does not list projects aimed for deletion' do
                expect(response).to have_gitlab_http_status(:ok)
                expect(response.body).not_to include aimed_for_deletion_project.name
              end
            end
          end
        end
      end
    end
  end

  describe 'GET #snippets' do
    before do
      sign_in(user)
    end

    context 'format html' do
      it 'renders snippets page' do
        get user_snippets_url user.username

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
      end
    end

    context 'format json' do
      it 'response with snippets json data' do
        get user_snippets_url user.username, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key('html')
      end
    end

    context 'external authorization' do
      subject { get user_snippets_url user.username }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe 'GET #exists' do
    context 'when user exists' do
      before do
        sign_in(user)

        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
      end

      let(:exists_true_response_body) { { exists: true }.to_json }

      it 'returns JSON indicating the user exists' do
        get user_exists_url user.username

        expect(response.body).to eq(exists_true_response_body)
      end

      context 'when the casing is different' do
        let(:user) { create(:user, username: 'CamelCaseUser') }

        it 'returns JSON indicating the user exists' do
          get user_exists_url user.username.downcase

          expect(response.body).to eq(exists_true_response_body)
        end
      end

      context 'when a group with the username exists' do
        let_it_be(:group) { create(:group, name: 'get-user-exists') }
        let_it_be(:subgroup) { create(:group, name: 'get-user-exists-child', parent: group) }

        it 'treats the top-level group as a reserved name' do
          get user_exists_url 'get-user-exists'

          expect(response.body).to eq(exists_true_response_body)
        end

        it 'treats the sub-group as not a reserved name' do
          get user_exists_url 'get-user-exists-child'

          expect(response.body).to eq({ exists: false }.to_json)
        end
      end
    end

    context 'when the user does not exist' do
      it 'will not show a signup page if registration is disabled' do
        stub_application_setting(signup_enabled: false)
        get user_exists_url 'foo'

        expected_json = { error: "You must be authenticated to access this path." }.to_json
        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.body).to eq(expected_json)
      end

      it 'returns JSON indicating the user does not exist' do
        get user_exists_url 'foo'

        expected_json = { exists: false }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when a user changed their username' do
        let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'old-username') }

        it 'returns JSON indicating a user by that username does not exist' do
          get user_exists_url 'old-username'

          expected_json = { exists: false }.to_json
          expect(response.body).to eq(expected_json)
        end
      end

      context 'when a project has the same name as a desired username' do
        let_it_be(:project) { create(:project, name: 'project-name') }

        it 'returns JSON indicating a user by that username does not exist' do
          get user_exists_url 'project-name'

          expected_json = { exists: false }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end

    context 'when the rate limit has been reached' do
      it 'returns status 429 Too Many Requests', :aggregate_failures do
        ip = '1.2.3.4'
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:username_exists, scope: ip).and_return(true)

        get user_exists_url(user.username), env: { REMOTE_ADDR: ip }

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  describe 'GET #groups' do
    before do
      sign_in(user)
    end

    context 'format html' do
      it 'renders groups page' do
        get user_groups_url user.username

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
      end
    end

    context 'format json' do
      before do
        setup_data
      end

      it 'response with groups data' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key('html')
      end

      it 'avoids N+1 DB queries', :request_store do
        # warm up cache so these initial queries would not leak in our QueryRecorder
        send_request

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          send_request
        end

        setup_data

        expect do
          send_request
        end.to issue_same_number_of_queries_as(control)
      end

      context 'pagination' do
        let!(:per_page_limit) { 3 }

        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(per_page_limit)
          create_list(:group, per_page_limit + 2).each { |group| group.add_owner(user) }
        end

        it 'paginates without count' do
          get user_groups_url user.username, format: :json

          expect(assigns(:groups).size).to eq(per_page_limit)
          expect(assigns(:groups)).to be_a(Kaminari::PaginatableWithoutCount)
        end
      end

      def setup_data
        create_list(:group, 2).each do |group|
          group.add_owner(user)
          create(:project, group: group)
          create(:group_member, group: group)
        end
      end

      def send_request
        get user_groups_url user.username, format: :json
      end
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting users at the root path' do
        context 'when requesting the canonical path' do
          let(:user) { create(:user, username: 'CamelCaseUser') }

          context 'with exactly matching casing' do
            it 'responds with success' do
              get user_url user.username

              expect(response).to be_successful
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get user_url user.username.downcase

              expect(response).to redirect_to(user)
              expect(flash[:notice]).to be_nil
            end
          end
        end

        shared_examples_for 'redirects to the canonical path' do
          it 'redirects to the canonical path' do
            get user_url redirect_route.path

            expect(response).to redirect_to(user)
            expect(flash[:notice]).to eq(user_moved_message(redirect_route, user))
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'old-path') }

          it_behaves_like 'redirects to the canonical path'

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'http') }

            # it does not modify the requested host and ...
            it_behaves_like 'redirects to the canonical path'
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'ser') }

            it_behaves_like 'redirects to the canonical path'
          end
        end
      end

      context 'when requesting users under the /users path' do
        context 'when requesting the canonical path' do
          let(:user) { create(:user, username: 'CamelCaseUser') }

          context 'with exactly matching casing' do
            it 'responds with success' do
              get user_projects_url user.username

              expect(response).to be_successful
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get user_projects_url user.username.downcase

              expect(response).to redirect_to(user_projects_path(user))
              expect(flash[:notice]).to be_nil
            end
          end
        end

        shared_examples_for 'redirects to the canonical path' do
          it 'redirects to the canonical path' do
            get user_projects_url redirect_route.path

            expect(response).to redirect_to(user_projects_path(user))
            expect(flash[:notice]).to eq(user_moved_message(redirect_route, user))
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'old-path') }

          it_behaves_like 'redirects to the canonical path'

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'http') }

            # it does not modify the requested host and ...
            it_behaves_like 'redirects to the canonical path'
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create!(path: 'ser') }

            # it does not modify the /users part of the path
            # (i.e. /users/ser should not become /ufoos/ser) and ...
            it_behaves_like 'redirects to the canonical path'
          end
        end
      end
    end
  end

  describe 'POST #follow' do
    context 'when over followee limit' do
      before do
        stub_const('Users::UserFollowUser::MAX_FOLLOWEE_LIMIT', 2)
        sign_in(user)
      end

      it 'alerts and not follow' do
        Users::UserFollowUser::MAX_FOLLOWEE_LIMIT.times { user.follow(create(:user)) }

        post user_follow_url(username: public_user.username)
        expect(response).to be_redirect

        expected_message = format(_("You can't follow more than %{limit} users. To follow more users, unfollow some others."), limit: Users::UserFollowUser::MAX_FOLLOWEE_LIMIT)
        expect(flash[:alert]).to eq(expected_message)
        expect(user).not_to be_following(public_user)
      end
    end

    context 'when user or followee disabled following' do
      before do
        sign_in(user)
      end

      it 'alerts and not follow if user disabled following' do
        user.enabled_following = false

        post user_follow_url(username: public_user.username)
        expect(response).to be_redirect

        expected_message = format(_('Action not allowed.'))
        expect(flash[:alert]).to eq(expected_message)
        expect(user).not_to be_following(public_user)
      end

      it 'alerts and not follow if followee disabled following' do
        public_user.enabled_following = false
        public_user.save!

        post user_follow_url(username: public_user.username)
        expect(response).to be_redirect

        expected_message = format(_('Action not allowed.'))
        expect(flash[:alert]).to eq(expected_message)
        expect(user).not_to be_following(public_user)
      end
    end
  end

  describe 'POST #unfollow' do
    before do
      sign_in(user)
    end

    context 'when unfollow is successful' do
      before do
        user.follow(public_user)
      end

      it 'removes the follow relationship and sets a success message' do
        post user_unfollow_url(username: public_user.username)
        expect(response).to be_redirect
        expect(user).not_to be_following(public_user)
      end
    end

    context 'when there is an error during unfollow' do
      it 'sets an error message and redirects' do
        post user_unfollow_url(username: public_user.username)
        expect(response).to be_redirect
        expect(flash[:alert]).to eq(_('Failed to unfollow user'))
      end
    end
  end

  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
      let(:url) { user_url(user, format: :atom) }
    end
  end

  def user_moved_message(redirect_route, user)
    "User '#{redirect_route.path}' was moved to '#{user.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
