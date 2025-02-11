# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runners, :aggregate_failures, factory_default: :keep, feature_category: :fleet_visibility do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:organization) { create_default(:organization) }
  let_it_be(:admin) { create(:user, :admin, last_activity_on: Time.current) }
  let_it_be(:users) { create_list(:user, 2) }
  let_it_be(:group_guest) { create(:user, guest_of: group) }
  let_it_be(:group_reporter) { create(:user, reporter_of: group) }
  let_it_be(:group_developer) { create(:user, developer_of: group) }
  let_it_be(:group_maintainer) { create(:user, maintainer_of: group) }

  let_it_be(:group) { create(:group, owners: users.first) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:project) do
    create(:project, creator_id: users.first.id, maintainers: users.first, reporters: users.second)
  end

  let_it_be(:project2) { create(:project, creator_id: users.first.id, maintainers: users.first) }

  let_it_be(:shared_runner, reload: true) { create(:ci_runner, :instance, :with_runner_manager, description: 'Shared runner') }
  let_it_be(:project_runner, reload: true) { create(:ci_runner, :project, description: 'Project runner', projects: [project]) }
  let_it_be(:two_projects_runner) { create(:ci_runner, :project, description: 'Two projects runner', projects: [project, project2]) }
  let_it_be(:group_runner_a) { create(:ci_runner, :group, description: 'Group runner A', groups: [group]) }
  let_it_be(:group_runner_b) { create(:ci_runner, :group, description: 'Group runner B', groups: [subgroup]) }

  let(:query) { {} }
  let(:extra_query_parts) { {} }
  let(:query_path) { query.merge(extra_query_parts).to_param }

  shared_context 'access token setup' do
    let(:current_user) { nil }
    let(:pat_user) { users.first }
    let(:pat) { create(:personal_access_token, user: pat_user, scopes: [scope]) }
    let(:extra_query_parts) { { private_token: pat.token } }
  end

  shared_examples 'when scope is forbidden' do |forbidden_scopes: []|
    where(:scope) { forbidden_scopes }

    with_them do
      it 'returns 403' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  shared_examples 'when scope is not allowed' do |scopes: []|
    where(:scope) { scopes }

    with_them do
      it 'returns 401' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /runners' do
    let(:path) { "/runners?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    context 'authorized user' do
      let(:current_user) { users.first }

      it 'returns response status and headers' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
      end

      it 'returns user available runners' do
        perform_request

        expect(json_response).to match_array [
          a_hash_including('description' => 'Project runner'),
          a_hash_including('description' => 'Two projects runner'),
          a_hash_including('description' => 'Group runner A'),
          a_hash_including('description' => 'Group runner B')
        ]
      end

      context 'with request authorized with access token' do
        include_context 'access token setup'

        it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner manage_runner]
      end

      context 'when filtering by scope' do
        let(:query) { { scope: :paused } }

        before_all do
          create(:ci_runner, :project, :paused, description: 'Paused project runner', projects: [project])
        end

        it 'filters runners by scope' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers

          expect(json_response).to match_array [
            a_hash_including('description' => 'Paused project runner')
          ]
        end

        context 'when is invalid' do
          let(:query) { { scope: :unknown } }

          it 'avoids filtering' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when filtering by type' do
        let(:query) { { type: type } }

        context 'with project_type type' do
          let(:type) { :project_type }

          it 'filters runners by type' do
            perform_request

            expect(json_response).to match_array [
              a_hash_including('description' => 'Project runner'),
              a_hash_including('description' => 'Two projects runner')
            ]
          end
        end

        context 'when type is invalid' do
          let(:type) { :bogus }

          it 'does not filter by invalid type' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'with a paused runner' do
        let_it_be(:runner) do
          create(:ci_runner, :project, :paused, description: 'Paused project runner', projects: [project])
        end

        context 'when filtering by paused' do
          let(:query) { { paused: true } }

          it 'filters runners by paused state' do
            perform_request

            expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused project runner'))
          end
        end

        context 'when filtering by status' do
          let(:query) { { status: :paused } }

          it 'filters runners by status' do
            perform_request

            expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused project runner'))
          end
        end

        context 'when filtering by invalid status' do
          let(:query) { { status: :bogus } }

          it 'does not filter' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when filtering by tag_list' do
          let(:query) { { tag_list: 'tag1,tag2' } }

          before_all do
            create(:ci_runner, :project, description: 'Runner tagged with tag1 and tag2', projects: [project], tag_list: %w[tag1 tag2])
            create(:ci_runner, :project, description: 'Runner tagged with tag2', projects: [project], tag_list: ['tag2'])
          end

          it 'filters runners by tag_list' do
            perform_request

            expect(json_response).to contain_exactly(
              a_hash_including('description' => 'Runner tagged with tag1 and tag2', 'active' => true, 'paused' => false)
            )
          end
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }

      it 'does not return runners' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /runners/:id/managers' do
    let(:path) { "/runners/#{runner.id}/managers" }

    subject(:perform_request) { get api(path, current_user) }

    context 'authorized user' do
      let(:current_user) { users.first }

      context 'when runner has managers' do
        let(:runner) { shared_runner }
        let(:manager) { runner.runner_managers.first }

        it 'returns all managers of the runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)

          expect(json_response).to contain_exactly(
            a_hash_including('id' => manager.id, 'version' => manager.version, 'architecture' => manager.architecture)
          )
        end
      end

      context 'when runner does not have managers' do
        let(:runner) { project_runner }

        it 'returns no managers' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)

          expect(json_response).to be_empty
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }

      let(:runner) { shared_runner }

      it 'does not return runners' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /runners/all' do
    let(:path) { "/runners/all?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    it_behaves_like 'GET request permissions for admin mode'

    context 'authorized user' do
      context 'with admin privileges', :enable_admin_mode do
        let(:current_user) { admin }

        it 'returns response status and headers' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
        end

        it 'returns all runners' do
          perform_request

          expect(json_response).to match_array [
            a_hash_including('description' => 'Project runner', 'is_shared' => false, 'active' => true, 'paused' => false, 'runner_type' => 'project_type'),
            a_hash_including('description' => 'Two projects runner', 'is_shared' => false, 'runner_type' => 'project_type'),
            a_hash_including('description' => 'Group runner A', 'is_shared' => false, 'runner_type' => 'group_type'),
            a_hash_including('description' => 'Group runner B', 'is_shared' => false, 'runner_type' => 'group_type'),
            a_hash_including('description' => 'Shared runner', 'is_shared' => true, 'runner_type' => 'instance_type')
          ]
        end

        context 'with request authorized with access token' do
          include_context 'access token setup' do
            let(:pat_user) { admin }
          end

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner manage_runner]
        end

        context 'when filtering runners by scope' do
          let(:query) { { scope: scope } }

          context 'with shared scope' do
            let(:scope) { :shared }

            it 'filters runners by scope' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to contain_exactly(
                a_hash_including('description' => 'Shared runner', 'is_shared' => true)
              )
            end
          end

          context 'with specific scope' do
            let(:scope) { :specific }

            it 'filters runners by scope' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers

              expect(json_response).to match_array [
                a_hash_including('description' => 'Project runner'),
                a_hash_including('description' => 'Two projects runner'),
                a_hash_including('description' => 'Group runner A'),
                a_hash_including('description' => 'Group runner B')
              ]
            end
          end

          context 'with invalid scope' do
            let(:scope) { :unknown }

            it 'avoids filtering' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when filtering runners by type' do
          let(:query) { { type: type } }

          context 'with project_type type' do
            let(:type) { :project_type }

            it 'filters runners by project type' do
              perform_request

              expect(json_response).to match_array [
                a_hash_including('description' => 'Project runner'),
                a_hash_including('description' => 'Two projects runner')
              ]
            end
          end

          context 'with group_type type' do
            let(:type) { :group_type }

            it 'filters runners by group type' do
              perform_request

              expect(json_response).to match_array [
                a_hash_including('description' => 'Group runner A'),
                a_hash_including('description' => 'Group runner B')
              ]
            end
          end

          context 'with invalid type' do
            let(:type) { :bogus }

            it 'does not filter by invalid type' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'with an paused runner' do
          let_it_be(:runner) { create(:ci_runner, :project, :paused, description: 'Paused project runner', projects: [project]) }

          context 'when filtering runners by paused status' do
            let(:query) { { paused: true } }

            it 'filters runners by status' do
              perform_request

              expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused project runner'))
            end
          end

          context 'when filtering runners by status' do
            let(:query) { { status: :paused } }

            it 'filters runners by status' do
              perform_request

              expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused project runner'))
            end

            context 'and status is invalid' do
              let(:query) { { status: :bogus } }

              it 'does not filter by invalid status' do
                perform_request

                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end
        end

        context 'when filtering by tag_list' do
          let(:query) { { tag_list: 'tag1,tag2' } }

          before_all do
            create(:ci_runner, :project, description: 'Runner tagged with tag1 and tag2', projects: [project], tag_list: %w[tag1 tag2])
            create(:ci_runner, :project, description: 'Runner tagged with tag2', projects: [project], tag_list: %w[tag2])
          end

          it 'filters runners by tag_list' do
            perform_request

            expect(json_response).to contain_exactly(
              a_hash_including('description' => 'Runner tagged with tag1 and tag2')
            )
          end
        end

        describe 'with ci_runner_machines' do
          before_all do
            version_ci_runner = create(:ci_runner, description: 'Runner with machine')
            version_16_ci_runner = create(:ci_runner, description: 'Runner with machine version 16')
            create(:ci_runner_machine, runner: version_ci_runner, version: '15.0.3')
            create(:ci_runner_machine, runner: version_16_ci_runner, version: '16.0.1')
          end

          context 'when filtering by version_prefix' do
            let(:query) { { version_prefix: version_prefix } }

            context 'with version_prefix set to "15.0"' do
              let(:version_prefix) { '15.0' }

              it 'filters runners by version_prefix' do
                perform_request

                expect(json_response).to contain_exactly(
                  a_hash_including('description' => 'Runner with machine', 'active' => true, 'paused' => false)
                )
              end
            end

            context 'with version_prefix set to "16"' do
              let(:version_prefix) { '16' }

              it 'filters runners by version_prefix' do
                perform_request

                expect(json_response).to contain_exactly(
                  a_hash_including('description' => 'Runner with machine version 16', 'active' => true, 'paused' => false)
                )
              end
            end

            context 'with version_prefix set to "25"' do
              let(:version_prefix) { '25' }

              it 'filters runners by version_prefix' do
                perform_request

                expect(json_response).to be_empty
              end
            end

            context 'with version_prefix set to invalid prefix "V15"' do
              let(:version_prefix) { 'V15' }

              it 'does not filter runners by version_prefix' do
                perform_request

                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end
        end
      end

      context 'without admin privileges' do
        let(:current_user) { users.first }

        it 'does not return runners list' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }

      it 'does not return runners' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /runners/:id' do
    let(:runner_id) { runner.id }
    let(:path) { "/runners/#{runner_id}?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:runner) { project_runner }
    end

    context 'admin user' do
      let(:current_user) { admin }

      context 'when runner is shared' do
        let(:runner) { shared_runner }

        it "returns runner's details" do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['description']).to eq(shared_runner.description)
          expect(json_response['maximum_timeout']).to be_nil
          expect(json_response['status']).to eq('never_contacted')
          expect(json_response['active']).to eq(true)
          expect(json_response['paused']).to eq(false)
          expect(json_response['maintenance_note']).to be_nil
        end
      end

      context 'when runner is a project runner' do
        let(:runner) { project_runner }

        it "returns forbidden" do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'with admin mode enabled', :enable_admin_mode do
          it "returns runner's details" do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['description']).to eq(runner.description)
          end

          it "returns the project's details" do
            perform_request

            expect(json_response['projects'].first['id']).to eq(project.id)
          end
        end
      end

      context 'when runner does not exist' do
        let(:runner_id) { non_existing_record_id }
        let(:runner) { project_runner }

        it 'returns 404', :enable_admin_mode do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    shared_examples 'an endpoint returning expected results' do
      context 'when the runner is a group runner' do
        let(:runner) { group_runner_a }

        it "returns the runner's details" do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['description']).to eq(runner.description)
          expect(json_response['groups'].first['id']).to eq(group.id)
        end
      end

      context "runner project's administrative user" do
        let(:current_user) { users.first }

        context 'when runner is not shared' do
          let(:runner) { project_runner }

          it "returns runner's details" do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['description']).to eq(runner.description)
          end
        end

        context 'when runner is shared' do
          let(:runner) { shared_runner }

          it "returns runner's details" do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['description']).to eq(runner.description)
          end
        end
      end
    end

    context 'authorized user' do
      let(:current_user) { users.first }

      it_behaves_like 'an endpoint returning expected results'

      context 'with request authorized with access token' do
        include_context 'access token setup'

        it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner] do
          let(:runner) { project_runner }
        end

        context 'with sufficient scope' do
          where(:scope) { %i[manage_runner read_api] }

          with_them do
            it_behaves_like 'an endpoint returning expected results'
          end
        end
      end
    end

    context 'other authorized user' do
      let(:current_user) { users.second }
      let(:runner) { project_runner }

      it "does not return project runner's details" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }
      let(:runner) { project_runner }

      it "does not return project runner's details" do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /runners/:id' do
    let(:runner_id) { runner.id }
    let(:path) { "/runners/#{runner_id}?#{query_path}" }

    subject(:perform_request) { put api(path, current_user), params: params }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:runner) { project_runner }
      let(:params) { { description: 'test' } }
    end

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin }

      # see https://gitlab.com/gitlab-org/gitlab-foss/issues/48625
      context 'single parameter update' do
        let(:runner) { shared_runner }

        context 'when changing description' do
          let(:params) { { description: "#{runner.description}_updated" } }

          it 'updates runner description' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.description).to eq(params[:description])
          end
        end

        context 'when changing active state' do
          let(:params) { { active: !runner.active } }

          it 'updates runner active state' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.active).to eq(params[:active])
          end
        end

        context 'when changing paused state' do
          let(:params) { { paused: runner.active } }

          it 'updates runner paused state' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.active).to eq(!params[:paused])
          end

          # This test ensures that it is possible to update any attribute on a runner that currently fails the
          # validation that ensures that there aren't too many tags associated with a runner
          context 'when changing unrelated runner attribute on an existing runner with too many tags' do
            let(:params) { { active: !runner.active } }
            let(:runner) do
              build(:ci_runner, :instance, tag_list: (1..::Ci::Runner::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" })
                .tap { |runner| runner.save!(validate: false) }
            end

            it 'unrelated runner attribute on an existing runner with too many tags' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(runner.reload.active).to eq(params[:active])
            end
          end
        end

        context 'when changing tag list' do
          let(:params) { { tag_list: %w[ruby2.1 pgsql mysql] } }

          it 'updates runner tag list' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.tag_list).to include('ruby2.1', 'pgsql', 'mysql')
          end
        end

        context 'when changing untagged flag' do
          let(:params) { { tag_list: %w[ruby2.1 pgsql mysql], run_untagged: 'false' } }

          it 'updates untagged flag' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.run_untagged?).to be(false)
          end
        end

        context 'when changing locked flag' do
          let(:params) { { locked: !runner.locked } }

          it 'updates locked flag' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.locked?).to be(params[:locked])
          end
        end

        context 'when changing access level' do
          let(:params) { { access_level: 'ref_protected' } }

          it 'updates access level' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.ref_protected?).to be_truthy
          end
        end

        context 'when changing maximum timeout' do
          let(:params) { { maximum_timeout: 1234 } }

          it 'updates maximum timeout' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.maximum_timeout).to eq(1234)
          end
        end

        context 'when changing maintenance note' do
          let(:params) { { maintenance_note: "#{runner.maintenance_note}_updated" } }

          it 'updates maintenance note' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(runner.reload.maintenance_note).to eq(params[:maintenance_note])
          end
        end

        context 'with no parameters' do
          let(:params) { {} }

          it 'fails with bad request' do
            perform_request

            runner.reload
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when runner is shared' do
        let(:runner) { shared_runner }
        let(:params) do
          {
            description: "#{runner.description}_updated",
            active: !runner.active,
            tag_list: %w[ruby2.1 pgsql mysql],
            run_untagged: 'false',
            locked: 'true',
            access_level: 'ref_protected',
            maximum_timeout: 1234
          }
        end

        it 'updates runner' do
          active = runner.active
          runner_queue_value = runner.ensure_runner_queue_value

          perform_request

          runner.reload
          expect(response).to have_gitlab_http_status(:ok)
          expect(runner.description).to eq(params[:description])
          expect(runner.active).to eq(!active)
          expect(runner.tag_list).to match_array(params[:tag_list])
          expect(runner.run_untagged?).to be(false)
          expect(runner.locked?).to be(true)
          expect(runner.ref_protected?).to be_truthy
          expect(runner.ensure_runner_queue_value).not_to eq(runner_queue_value)
          expect(runner.maximum_timeout).to eq(1234)
        end

        context 'with request authorized with access token' do
          include_context 'access token setup' do
            let(:pat_user) { admin }
          end

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

          context 'with sufficient scope' do
            let(:scope) { :manage_runner }

            it 'updates runner' do
              perform_request

              runner.reload
              expect(response).to have_gitlab_http_status(:ok)
              expect(runner.description).to eq(params[:description])
            end
          end
        end
      end

      context 'when runner is not shared' do
        let(:runner) { project_runner }
        let(:params) { { description: 'test' } }

        it 'updates runner' do
          description = runner.description
          runner_queue_value = runner.ensure_runner_queue_value

          perform_request

          runner.reload
          expect(response).to have_gitlab_http_status(:ok)
          expect(runner.description).to eq(params[:description])
          expect(runner.description).not_to eq(description)
          expect(runner.ensure_runner_queue_value).not_to eq(runner_queue_value)
        end
      end

      context 'when runner id does not exist' do
        let(:runner_id) { non_existing_record_id }
        let(:params) { { description: 'test' } }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'authorized user' do
      let(:current_user) { users.first }
      let(:params) { { description: 'test' } }

      context 'when runner is shared' do
        let(:runner) { shared_runner }

        it 'does not update runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'with request authorized with access token' do
          include_context 'access token setup'

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[manage_runner create_runner read_api]
        end
      end

      context 'when runner is not shared' do
        let(:runner) { project_runner }

        it 'updates runner description' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(runner.reload.description).to eq(params[:description])
        end

        context 'with request authorized with access token' do
          include_context 'access token setup'

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

          context 'with sufficient scope' do
            let(:scope) { :manage_runner }

            it 'updates runner description' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(runner.reload.description).to eq(params[:description])
            end
          end
        end

        context 'when user does not have access to runner' do
          let(:current_user) { users.second }

          it 'does not update runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }
      let(:runner) { project_runner }
      let(:params) { { description: 'test' } }

      it 'does not update project runner' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(runner.reload.description).not_to eq(params[:description])
      end
    end
  end

  describe 'DELETE /runners/:id' do
    let(:runner_id) { runner.id }
    let(:path) { "/runners/#{runner_id}?#{query_path}" }

    subject(:perform_request) { delete api(path, current_user) }

    it_behaves_like 'DELETE request permissions for admin mode' do
      let(:runner) { shared_runner }
    end

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin }

      context 'when runner is shared' do
        let(:runner) { shared_runner }

        it 'deletes runner' do
          expect_next_instance_of(Ci::Runners::UnregisterRunnerService, runner, current_user) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect do
            perform_request

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { ::Ci::Runner.instance_type.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api(path, current_user) }
        end

        context 'with request authorized with access token' do
          include_context 'access token setup' do
            let(:pat_user) { admin }
          end

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner]

          context 'with sufficient scope' do
            let(:scope) { :manage_runner }

            it 'deletes runner' do
              expect_next_instance_of(Ci::Runners::UnregisterRunnerService, runner, pat_user) do |service|
                expect(service).to receive(:execute).once.and_call_original
              end

              expect do
                perform_request

                expect(response).to have_gitlab_http_status(:no_content)
              end.to change { ::Ci::Runner.instance_type.count }.by(-1)
            end
          end
        end
      end

      context 'when runner is not shared' do
        let(:runner) { project_runner }

        it 'deletes used project runner' do
          expect_next_instance_of(Ci::Runners::UnregisterRunnerService, runner, current_user) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect do
            perform_request

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { ::Ci::Runner.project_type.count }.by(-1)
        end
      end

      context 'when runner does not exist' do
        let(:runner_id) { non_existing_record_id }

        it 'returns 404' do
          allow_next_instance_of(Ci::Runners::UnregisterRunnerService) do |service|
            expect(service).not_to receive(:execute)
          end

          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'authorized user' do
      let(:current_user) { users.first }

      context 'when runner is shared' do
        let(:runner) { shared_runner }

        it 'does not delete runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'with request authorized with access token' do
          include_context 'access token setup'

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[manage_runner create_runner read_api]
        end
      end

      context 'with a project runner' do
        let(:runner) { project_runner }

        context 'when user does not have access to runner' do
          let(:current_user) { users.second }

          it 'does not delete runner without access to it' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when runner is associated with more than one project' do
          let(:runner) { two_projects_runner }

          it 'does not delete project runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when runner is associated with one owned project' do
          let(:runner) { project_runner }

          it 'deletes project runner' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:no_content)
            end.to change { ::Ci::Runner.project_type.count }.by(-1)
          end

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

            context 'with sufficient scope' do
              let(:scope) { :manage_runner }

              it 'deletes project runner' do
                expect do
                  perform_request

                  expect(response).to have_gitlab_http_status(:no_content)
                end.to change { ::Ci::Runner.project_type.count }.by(-1)
              end
            end
          end
        end

        it_behaves_like '412 response' do
          let(:request) { api(path, current_user) }
        end
      end

      context 'with group runner' do
        let(:runner) { group_runner_a }

        context 'when user has guest access' do
          let(:current_user) { group_guest }

          it 'does not delete runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user has reporter access' do
          let(:current_user) { group_reporter }

          it 'does not delete runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user has developer access' do
          let(:current_user) { group_developer }

          it 'does not delete runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user has maintainer access' do
          let(:current_user) { group_maintainer }

          it 'does not delete runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user has owner access' do
          let(:current_user) { users.first }

          it 'deletes runner' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:no_content)
            end.to change { ::Ci::Runner.group_type.count }.by(-1)
          end

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

            context 'with sufficient scope' do
              let(:scope) { :manage_runner }

              it 'deletes group runner' do
                expect do
                  perform_request

                  expect(response).to have_gitlab_http_status(:no_content)
                end.to change { ::Ci::Runner.group_type.count }.by(-1)
              end
            end
          end
        end

        it_behaves_like '412 response' do
          let(:request) { api(path, current_user) }
        end
      end

      context 'with inherited group runner' do
        let(:runner) { group_runner_b }

        context 'when user has owner access' do
          let(:current_user) { users.first }

          it 'deletes group runner' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:no_content)
            end.to change { ::Ci::Runner.group_type.count }.by(-1)
          end

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

            context 'with sufficient scope' do
              let(:scope) { :manage_runner }

              it 'deletes group runner' do
                expect do
                  perform_request

                  expect(response).to have_gitlab_http_status(:no_content)
                end.to change { ::Ci::Runner.group_type.count }.by(-1)
              end
            end
          end
        end

        it_behaves_like '412 response' do
          let(:request) { api(path, current_user) }
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }
      let(:runner) { project_runner }

      it 'does not delete runner' do
        allow_next_instance_of(Ci::Runners::UnregisterRunnerService) do |service|
          expect(service).not_to receive(:execute)
        end

        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /runners/:id/reset_authentication_token' do
    let(:runner_id) { runner.id }
    let(:path) { "/runners/#{runner_id}/reset_authentication_token?#{query_path}" }

    subject(:perform_request) { post api(path, current_user) }

    shared_examples 'a runner accepting authentication token reset' do
      it 'resets runner authentication token' do
        expect do
          perform_request

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response).to eq({ 'token' => runner.reload.token, 'token_expires_at' => nil })
        end.to change { runner.reload.token }
      end
    end

    it_behaves_like 'POST request permissions for admin mode' do
      let(:runner) { project_runner }
      let(:params) { {} }
    end

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin }

      context 'when runner is shared' do
        let(:runner) { shared_runner }

        it_behaves_like 'a runner accepting authentication token reset'

        context 'with request authorized with access token' do
          include_context 'access token setup' do
            let(:pat_user) { admin }
          end

          it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

          context 'with sufficient scope' do
            let(:scope) { :manage_runner }

            it_behaves_like 'a runner accepting authentication token reset'
          end
        end
      end

      context 'when runner does not exist' do
        let(:runner_id) { non_existing_record_id }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'authorized user' do
      context 'with project runner' do
        let(:runner) { project_runner }

        context 'when user does not have access to runner' do
          let(:current_user) { users.second }

          it 'does not reset runner' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { runner.reload.token }
          end

          context 'with request authorized with access token' do
            include_context 'access token setup' do
              let(:pat_user) { users.second }
            end

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[manage_runner create_runner read_api]
          end
        end

        context 'when user has access to runner' do
          let(:current_user) { users.first }

          it_behaves_like 'a runner accepting authentication token reset'

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

            context 'with sufficient scope' do
              let(:scope) { :manage_runner }

              it_behaves_like 'a runner accepting authentication token reset'
            end
          end
        end
      end

      context 'with group runner' do
        let(:runner) { group_runner_a }

        context 'when user has guest access' do
          let(:current_user) { group_guest }

          it 'does not reset runner authentication token' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { runner.reload.token }
          end
        end

        context 'when user has reporter access' do
          let(:current_user) { group_reporter }

          it 'does not reset runner authentication token' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { runner.reload.token }
          end
        end

        context 'when user has developer access' do
          let(:current_user) { group_developer }

          it 'does not reset runner authentication token' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { runner.reload.token }
          end
        end

        context 'when user has maintainer access' do
          let(:current_user) { group_maintainer }

          it 'does not reset runner authentication token' do
            expect do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { runner.reload.token }
          end
        end

        context 'when user has owner access' do
          let(:current_user) { users.first }

          it_behaves_like 'a runner accepting authentication token reset'

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner read_api]

            context 'with sufficient scope' do
              let(:scope) { :manage_runner }

              it_behaves_like 'a runner accepting authentication token reset'
            end
          end

          context 'when runner token has expiration time', :freeze_time do
            before do
              group.update!(runner_token_expiration_interval: 5.days)
            end

            it 'resets group runner authentication token with owner access with expiration time' do
              expect(runner.reload.token_expires_at).to be_nil

              expect do
                perform_request

                runner.reload
                expect(response).to have_gitlab_http_status(:success)
                expect(json_response).to eq({ 'token' => runner.token, 'token_expires_at' => runner.token_expires_at.iso8601(3) })
                expect(runner.token_expires_at).to eq(5.days.from_now)
              end.to change { runner.reload.token }
            end
          end
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }
      let(:runner) { project_runner }

      it 'does not reset authentication token' do
        expect do
          perform_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end.not_to change { runner.reload.token }
      end
    end
  end

  describe 'GET /runners/:id/jobs' do
    let_it_be(:shared_runner_manager1) { create(:ci_runner_machine, runner: shared_runner, system_xid: 'id2') }
    let_it_be(:jobs) do
      project_runner_manager1 = create(:ci_runner_machine, runner: project_runner, system_xid: 'id1')
      project_runner_manager2 = create(:ci_runner_machine, runner: two_projects_runner, system_xid: 'id1')
      pipeline_args = { pipeline: create(:ci_pipeline, project: project) }
      pipeline2_args = { pipeline: create(:ci_pipeline, project: project2) }

      [
        create(:ci_build, pipeline: create(:ci_pipeline)),
        create(:ci_build, :running, runner_manager: shared_runner_manager1, **pipeline_args),
        create(:ci_build, :failed, runner_manager: shared_runner_manager1, **pipeline_args),
        create(:ci_build, :running, runner_manager: project_runner_manager1, **pipeline_args),
        create(:ci_build, :failed, runner_manager: project_runner_manager1, **pipeline_args),
        create(:ci_build, :running, runner_manager: project_runner_manager2, **pipeline_args),
        create(:ci_build, :running, runner_manager: project_runner_manager2, **pipeline2_args)
      ]
    end

    let(:runner_id) { runner.id }
    let(:path) { "/runners/#{runner_id}/jobs?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:runner) { project_runner }
    end

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin }

      context 'when runner exists' do
        context 'when runner is shared' do
          let(:runner) { shared_runner }

          it 'return jobs' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers

            expect(json_response).to match([
              a_hash_including('id' => jobs[1].id),
              a_hash_including('id' => jobs[2].id)
            ])
          end

          it_behaves_like 'an endpoint with keyset pagination', invalid_order: nil do
            let(:first_record) { jobs[2] }
            let(:second_record) { jobs[1] }
            let(:api_call) { api(path, current_user) }
          end

          context 'with request authorized with access token' do
            include_context 'access token setup' do
              let(:pat_user) { admin }
            end

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner]

            context 'with sufficient scope' do # rubocop:disable RSpec/MultipleMemoizedHelpers -- Need helpers for scenarios
              let(:scope) { :manage_runner }

              it 'return jobs' do
                perform_request

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers

                expect(json_response).to match([
                  a_hash_including('id' => jobs[1].id),
                  a_hash_including('id' => jobs[2].id)
                ])
              end
            end
          end
        end

        context 'when runner is a project runner' do
          let(:runner) { project_runner }

          it 'return jobs' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers

            expect(json_response).to match([
              a_hash_including('id' => jobs[3].id),
              a_hash_including('id' => jobs[4].id)
            ])
          end

          context 'with request authorized with access token' do
            include_context 'access token setup'

            it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner]

            context 'with sufficient scope' do # rubocop:disable RSpec/MultipleMemoizedHelpers -- Need helpers for scenarios
              let(:scope) { :manage_runner }

              it 'return jobs' do
                perform_request

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers

                expect(json_response).to match([
                  a_hash_including('id' => jobs[3].id),
                  a_hash_including('id' => jobs[4].id)
                ])
              end
            end
          end

          context 'when user does not have authorization to see all jobs' do
            let(:runner) { two_projects_runner }
            let(:current_user) { users.second }

            before_all do
              project.add_guest(users.second)
              project2.add_maintainer(users.second)
            end

            it 'shows only jobs it has permission to see' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to match([a_hash_including('id' => jobs[6].id)])
            end

            context 'with request authorized with access token' do
              include_context 'access token setup' do
                let(:pat_user) { users.second }
              end

              it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner]

              context 'with sufficient scope' do # rubocop:disable RSpec/MultipleMemoizedHelpers -- Need helpers for scenarios
                let(:scope) { :manage_runner }

                it 'shows only jobs it has permission to see' do
                  perform_request

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response).to include_pagination_headers
                  expect(json_response).to match([a_hash_including('id' => jobs[6].id)])
                end
              end
            end
          end

          context 'when valid status is provided' do
            let(:query) { { status: :failed } }

            it 'return filtered jobs' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers

              expect(json_response).to match([a_hash_including('id' => jobs[4].id)])
            end
          end

          context 'when valid order_by is provided' do
            let(:query) { { order_by: :id } }

            context 'when sort order is not specified' do
              it 'return jobs in descending order' do
                perform_request

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers

                expect(json_response).to match([
                  a_hash_including('id' => jobs[4].id),
                  a_hash_including('id' => jobs[3].id)
                ])
              end
            end

            context 'when sort order is specified as asc' do
              let(:query) { { order_by: :id, sort: :asc } }

              it 'return jobs sorted in ascending order' do
                perform_request

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers

                expect(json_response).to match([
                  a_hash_including('id' => jobs[3].id),
                  a_hash_including('id' => jobs[4].id)
                ])
              end
            end
          end

          context 'when invalid status is provided' do
            let(:query) { { status: 'non-existing' } }

            it 'return 400' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'when invalid order_by is provided' do
            let(:query) { { order_by: 'non-existing' } }

            it 'return 400' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'when invalid sort is provided' do
            let(:query) { { sort: 'non-existing' } }

            it 'return 400' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end

      describe 'eager loading' do
        let!(:runner) { shared_runner }

        it 'avoids N+1 DB queries', :use_sql_query_cache, :freeze_time do
          another_admin = create(:admin, last_activity_on: Time.current) # Avoid noise from Users::ActivityService
          pipeline = create(:ci_pipeline, project: project2, sha: 'ddd0f15ae83993f5cb66a927a28673882e99100b')

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api(path, current_user)
          end

          create(:ci_build, :failed, runner: shared_runner, project: project2, pipeline: pipeline)

          expect do
            get api(path, another_admin)
          end.not_to exceed_all_query_limit(control)
        end

        it 'batches loading of commits' do
          project_with_repo = create(:project, :repository)
          shared_runner_manager1 = create(:ci_runner_machine, runner: shared_runner, system_xid: 'id1')

          pipeline = create(:ci_pipeline, project: project_with_repo, sha: 'ddd0f15ae83993f5cb66a927a28673882e99100b')
          create(:ci_build, :running, runner_manager: shared_runner_manager1, project: project_with_repo, pipeline: pipeline)

          pipeline = create(:ci_pipeline, project: project_with_repo, sha: 'c1c67abbaf91f624347bb3ae96eabe3a1b742478')
          create(:ci_build, :failed, runner_manager: shared_runner_manager1, project: project_with_repo, pipeline: pipeline)

          pipeline = create(:ci_pipeline, project: project_with_repo, sha: '1a0b36b3cdad1d2ee32457c102a8c0b7056fa863')
          create(:ci_build, :failed, runner_manager: shared_runner_manager1, project: project_with_repo, pipeline: pipeline)

          expect_next_instance_of(Repository) do |repo|
            expect(repo).to receive(:commits_by).with(oids:
              %w[
                1a0b36b3cdad1d2ee32457c102a8c0b7056fa863
                c1c67abbaf91f624347bb3ae96eabe3a1b742478
              ]).once.and_call_original
          end

          get api(path, current_user), params: { per_page: 2, order_by: 'id', sort: 'desc' }
        end
      end

      context "when runner doesn't exist" do
        let(:runner_id) { non_existing_record_id }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context "runner project's administrative user" do
      let(:current_user) { users.first }

      context 'when runner exists' do
        context 'when runner is shared' do
          let(:runner) { shared_runner }

          it 'returns 403' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when runner is a project runner' do
          let(:runner) { project_runner }

          it 'return jobs' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers

            expect(json_response).to match([
              a_hash_including('id' => jobs[3].id),
              a_hash_including('id' => jobs[4].id)
            ])
          end

          context 'when valid status is provided' do
            let(:query) { { status: :failed } }

            it 'return filtered jobs' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers

              expect(json_response).to match([
                a_hash_including('id' => jobs[4].id)
              ])
            end
          end

          context 'when invalid status is provided' do
            let(:query) { { status: 'non-existing' } }

            it 'return 400' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end

      context "when runner doesn't exist" do
        let(:runner_id) { non_existing_record_id }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'other authorized user' do
        let(:current_user) { users.second }
        let(:runner) { shared_runner }

        it 'does not return jobs' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'unauthorized user' do
        let(:current_user) { nil }
        let(:runner) { shared_runner }

        it 'does not return jobs' do
          perform_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'with system_id param' do
      let(:extra_query_parts) { { system_id: 'id1' } }
      let(:current_user) { users.first }

      context 'with project runner' do
        let(:runner) { project_runner }

        it 'returns jobs from the runner manager' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_limited_pagination_headers
          expect(response.headers).not_to include('X-Total', 'X-Total-Pages')

          expect(json_response).to match([
            a_hash_including('id' => jobs[3].id),
            a_hash_including('id' => jobs[4].id)
          ])
        end
      end

      context 'when system_id does not match runner', :enable_admin_mode do
        let(:current_user) { admin }
        let(:runner) { shared_runner }

        it 'does not return jobs' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end
      end
    end
  end

  shared_examples_for 'unauthorized access to runners list' do
    context 'authorized user without maintainer privileges' do
      let(:current_user) { users.second }

      it "does not return group's runners" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }

      it "does not return project's runners" do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/runners' do
    let(:path) { "/projects/#{project.id}/runners?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    context 'admin user', :enable_admin_mode do
      let(:current_user) { admin }

      it 'returns response status and headers' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
      end
    end

    context 'authorized user with maintainer privileges' do
      let(:current_user) { users.first }

      it 'returns all runners' do
        perform_request

        expect(json_response).to match_array [
          a_hash_including('description' => 'Project runner', 'active' => true, 'paused' => false),
          a_hash_including('description' => 'Two projects runner', 'active' => true, 'paused' => false),
          a_hash_including('description' => 'Shared runner', 'active' => true, 'paused' => false)
        ]
      end

      context 'when filtering by scope' do
        let(:query) { { scope: :specific } }

        it 'filters runners by scope' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers

          expect(json_response).to contain_exactly(
            a_hash_including('description' => 'Project runner'),
            a_hash_including('description' => 'Two projects runner')
          )
        end

        context 'and scope is unknown' do
          let(:query) { { scope: :unknown } }

          it 'avoids filtering' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when filtering by type' do
        let(:query) { { type: :project_type } }

        it 'filters runners by type' do
          perform_request

          expect(json_response).to contain_exactly(
            a_hash_including('description' => 'Project runner'),
            a_hash_including('description' => 'Two projects runner')
          )
        end

        context 'and type is invalid' do
          let(:query) { { type: :bogus } }

          it 'does not filter' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'with a paused runner' do
        let_it_be(:runner) { create(:ci_runner, :project, :paused, description: 'Paused project runner', projects: [project]) }

        context 'when filtering by paused status' do
          let(:query) { { paused: true } }

          it 'filters runners by status' do
            perform_request

            expect(json_response).to contain_exactly(
              a_hash_including('description' => 'Paused project runner')
            )
          end
        end

        context 'when filtering by status' do
          let(:query) { { status: :paused } }

          it 'filters runners by status' do
            perform_request

            expect(json_response).to contain_exactly(
              a_hash_including('description' => 'Paused project runner')
            )
          end

          context 'and status is invalid' do
            let(:query) { { status: :bogus } }

            it 'does not filter by invalid status' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end

      context 'when filtering by tag_list' do
        let(:query) { { tag_list: 'tag1,tag2' } }

        before_all do
          create(:ci_runner, :project, description: 'Runner tagged with tag1 and tag2', projects: [project], tag_list: %w[tag1 tag2])
          create(:ci_runner, :project, description: 'Runner tagged with tag2', projects: [project], tag_list: %w[tag2])
        end

        it 'filters runners by tag_list' do
          perform_request

          expect(json_response).to contain_exactly(
            a_hash_including('description' => 'Runner tagged with tag1 and tag2')
          )
        end
      end
    end

    context 'with request authorized with access token' do
      include_context 'access token setup'

      it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner manage_runner]

      context 'with sufficient scope' do
        let(:scope) { :read_api }

        it 'returns all runners' do
          perform_request

          expect(json_response).to match_array [
            a_hash_including('description' => 'Project runner', 'active' => true, 'paused' => false),
            a_hash_including('description' => 'Two projects runner', 'active' => true, 'paused' => false),
            a_hash_including('description' => 'Shared runner', 'active' => true, 'paused' => false)
          ]
        end
      end
    end

    it_behaves_like 'unauthorized access to runners list'
  end

  describe 'GET /groups/:id/runners' do
    let(:path) { "/groups/#{group.id}/runners?#{query_path}" }

    subject(:perform_request) { get api(path, current_user) }

    context 'authorized user with maintainer privileges' do
      let(:current_user) { users.first }

      it 'returns all runners' do
        perform_request

        expect(json_response).to match_array(
          [
            a_hash_including('description' => 'Group runner A', 'active' => true, 'paused' => false),
            a_hash_including('description' => 'Shared runner', 'active' => true, 'paused' => false)
          ])
      end

      context 'filter by type' do
        let(:query) { { type: type } }

        context 'with type group_type' do
          let(:type) { :group_type }

          it 'returns group runners' do
            perform_request

            expect(json_response).to match_array([a_hash_including('description' => 'Group runner A')])
          end
        end

        context 'with type instance_type' do
          let(:type) { :instance_type }

          it 'returns instance runners' do
            perform_request

            expect(json_response).to match_array([a_hash_including('description' => 'Shared runner')])
          end
        end

        # TODO: Remove when REST API v5 is implemented (https://gitlab.com/gitlab-org/gitlab/-/issues/351466)
        context 'with type project_type' do
          let(:type) { :project_type }

          it 'returns empty result when type does not match' do
            perform_request

            expect(json_response).to be_empty
          end
        end

        context 'with invalid type' do
          let(:type) { :bogus }

          it 'does not filter by invalid type' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'with a paused runner' do
        let_it_be(:runner) { create(:ci_runner, :group, :paused, description: 'Paused group runner', groups: [group]) }

        context 'when filtering by paused status' do
          let(:query) { { paused: true } }

          it 'filters runners by status' do
            perform_request

            expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused group runner'))
          end
        end

        context 'when filtering by status' do
          let(:query) { { status: :paused } }

          it 'returns runners by valid status' do
            perform_request

            expect(json_response).to contain_exactly(a_hash_including('description' => 'Paused group runner'))
          end

          context 'and status is invalid' do
            let(:query) { { status: :bogus } }

            it 'does not filter by invalid status' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end

      context 'when filtering by tag_list' do
        let(:query) { { tag_list: 'tag1,tag2' } }

        before_all do
          create(:ci_runner, :group, description: 'Runner tagged with tag1 and tag2', groups: [group], tag_list: %w[tag1 tag2])
          create(:ci_runner, :group, description: 'Runner tagged with tag2', groups: [group], tag_list: %w[tag1])
        end

        it 'filters runners by tag_list' do
          perform_request

          expect(json_response).to contain_exactly(a_hash_including('description' => 'Runner tagged with tag1 and tag2'))
        end
      end
    end

    context 'with request authorized with access token' do
      include_context 'access token setup'

      it_behaves_like 'when scope is forbidden', forbidden_scopes: %i[create_runner manage_runner]

      context 'with sufficient scope' do
        let(:scope) { :read_api }

        it 'returns all runners' do
          perform_request

          expect(json_response).to match_array(
            [
              a_hash_including('description' => 'Group runner A', 'active' => true, 'paused' => false),
              a_hash_including('description' => 'Shared runner', 'active' => true, 'paused' => false)
            ])
        end
      end
    end

    it_behaves_like 'unauthorized access to runners list'
  end

  describe 'POST /projects/:id/runners' do
    let(:params) { { runner_id: runner.id } }
    let(:path) { "/projects/#{project.id}/runners" }

    subject(:perform_request) { post api(path, current_user), params: params }

    it_behaves_like 'POST request permissions for admin mode' do
      let!(:new_project_runner) { create(:ci_runner, :project, projects: [project2]) }
      let(:params) { { runner_id: new_project_runner.id } }
      let(:failed_status_code) { :not_found }
    end

    context 'authorized user' do
      let_it_be(:project_runner2) { create(:ci_runner, :project, projects: [project2]) }

      let(:current_user) { users.first }
      let(:runner) { project_runner2 }

      it 'assigns project runner' do
        expect { perform_request }.to change { project.runners.count }.by(+1)

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'when assigning already assigned runner' do
        let(:runner) { project_runner }

        it 'avoids changes' do
          expect { perform_request }.to change { project.runners.count }.by(0)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when assigning locked runner' do
        let(:runner) { project_runner2 }

        before_all do
          project_runner2.update!(locked: true)
        end

        it 'does not assign runner' do
          expect { perform_request }.not_to change { project.runners.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when assigning shared runner' do
        let(:runner) { shared_runner }

        it 'does not assign runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when assigning group runner' do
        let(:runner) { group_runner_a }

        it 'does not assign runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'user is admin', :enable_admin_mode do
        let(:current_user) { admin }

        context 'when project runner is used' do
          let!(:new_project_runner) { create(:ci_runner, :project, projects: [project2]) }
          let(:runner) { new_project_runner }

          it 'assigns any project runner' do
            expect { perform_request }.to change { project.runners.count }.by(+1)

            expect(response).to have_gitlab_http_status(:created)
          end

          context 'when it exceeds the application limits' do
            before do
              create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
            end

            it 'does not assign runner' do
              expect { perform_request }.not_to change { project.runners.count }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end

      context 'with request authorized with access token' do
        include_context 'access token setup'

        where(:scope) { %i[create_runner manage_runner] }

        it_behaves_like 'when scope is not allowed', scopes: %i[create_runner manage_runner]
      end

      context 'when no runner_id param is provided' do
        let(:params) { {} }

        it 'raises an error' do
          perform_request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when user does not have permissions' do
        let(:current_user) { users.second }
        let(:runner) { project_runner }

        it 'does not assign runner' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'user is not admin and does not have access to project runner' do
      let_it_be(:new_project_runner) { create(:ci_runner, :project, projects: [project]) }

      let(:runner) { new_project_runner }
      let(:current_user) { create(:user, guest_of: project) }

      it 'does not assign runner' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }
      let(:runner) { project_runner }

      it 'does not assign runner' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/runners/:runner_id' do
    let(:runner_id) { two_projects_runner.id }
    let(:project_to_delete_from) { project2 }
    let(:path) { "/projects/#{project_to_delete_from.id}/runners/#{runner_id}" }

    subject(:perform_request) { delete api(path, current_user) }

    context 'authorized user' do
      let(:current_user) { users.first }

      context 'when runner have more than one associated project' do
        let(:runner_id) { two_projects_runner.id }

        it "unassigns project's runner", :aggregate_failures do
          expect { perform_request }.to change { project_to_delete_from.runners.count }.by(-1)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        context 'when runner is unassigned from project owner' do
          let(:project_to_delete_from) { project }

          it "does not unassign project's runner" do
            expect { perform_request }.not_to change { project_to_delete_from.runners.count }

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        it_behaves_like '412 response' do
          let(:request) { api(path, current_user) }
        end

        context 'with request authorized with access token' do
          include_context 'access token setup'

          it_behaves_like 'when scope is not allowed', scopes: %i[create_runner manage_runner]
        end
      end

      context 'when runner have a single associated project' do
        let(:runner_id) { project_runner.id }
        let(:project_to_delete_from) { project }

        it "does not unassign project's runner" do
          expect { perform_request }.not_to change { project_to_delete_from.runners.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when runner is not found' do
        let(:runner_id) { non_existing_record_id }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'authorized user without permissions' do
      let(:current_user) { create(:user, developer_of: project_to_delete_from) }

      it "does not unassign project's runner" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      let(:current_user) { nil }

      it "does not unassign project's runner" do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
