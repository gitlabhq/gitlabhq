# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationController, type: :request, feature_category: :shared do
  let_it_be_with_reload(:user) { create(:user) }

  it_behaves_like 'Base action controller' do
    before do
      sign_in(user)
    end

    subject(:request) { get root_path }
  end

  it 'does not send Link header', :use_clean_rails_redis_caching do
    sign_in(user)

    get root_path

    expect(response.headers['Link']).to be_nil
  end

  describe 'session expiration' do
    context 'when user is authenticated' do
      it 'sets the expire_after option from session_expire_delay setting' do
        sign_in(user)

        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to eq(
          Settings.gitlab['session_expire_delay'] * 60
        )
      end
    end

    context 'when user is unauthenticated' do
      it 'sets the expire_after option from unauthenticated_session_expire_delay' do
        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to eq(
          Settings.gitlab['unauthenticated_session_expire_delay']
        )
      end
    end
  end

  describe 'unknown route' do
    # This spec targets CI environment with precompiled assets to trigger
    # Sprockets' `File.binread` and find encoding issues.
    #
    # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17627#note_1782396646
    it 'returns 404 even when locale contains UTF-8 chars' do
      user.update!(preferred_language: 'ZH-cn')

      sign_in(user)

      get "/some/undefined/path"

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.body.encoding.name).to eq('UTF-8')
    end
  end

  describe 'User-Agent header' do
    before do
      sign_in(user)

      get root_path, headers: { 'User-Agent': user_agent }
    end

    context 'when missing' do
      let(:user_agent) { nil }

      it { expect(response).to have_gitlab_http_status(:ok) }
    end

    context 'when correct' do
      let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }

      it { expect(response).to have_gitlab_http_status(:ok) }
    end

    context 'when too long' do
      let(:user_agent) { 'a' * 3000 }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  describe 'HTTP Router headers' do
    before do
      sign_in(user)
    end

    let(:headers) do
      {
        'X-Gitlab-Http-Router-Rule-Action' => 'classify',
        'X-Gitlab-Http-Router-Rule-Type' => 'FIRST_CELL'
      }
    end

    subject(:perform_request) do
      get root_path, headers: headers
    end

    it 'includes the HTTP ROUTER headers in ApplicationContext' do
      expect_next_instance_of(RootController) do |controller|
        expect(controller).to receive(:index).and_wrap_original do |m, *args|
          m.call(*args)

          expect(Gitlab::ApplicationContext.current).to include(
            'meta.http_router_rule_action' => 'classify',
            'meta.http_router_rule_type' => 'FIRST_CELL'
          )
        end
      end

      perform_request
    end

    context 'for counters' do
      let(:http_router_rule_counter) { Gitlab::Metrics.counter(:gitlab_http_router_rule_total, 'description') }

      context 'when the headers are present' do
        context 'for classify action' do
          it 'increments the counter' do
            expect { perform_request }.to change {
              http_router_rule_counter.get(rule_action: 'classify', rule_type: 'FIRST_CELL')
            }.by(1)
          end
        end

        context 'for proxy action' do
          let(:headers) do
            {
              'X-Gitlab-Http-Router-Rule-Action' => 'proxy'
            }
          end

          it 'increments the counter' do
            expect { perform_request }.to change {
              http_router_rule_counter.get(rule_action: 'proxy', rule_type: nil)
            }.by(1)
          end
        end

        context 'for invalid action and type' do
          let(:headers) do
            {
              'X-Gitlab-Http-Router-Rule-Action' => 'invalid',
              'X-Gitlab-Http-Router-Rule-Type' => 'invalid'
            }
          end

          it 'does not increment the counter' do
            expect { perform_request }.to change {
              http_router_rule_counter.get(rule_action: 'invalid', rule_type: 'invalid')
            }.by(0)
          end
        end

        context 'when action is not present and type is present' do
          let(:headers) do
            {
              'X-Gitlab-Http-Router-Rule-Type' => 'FIRST_CELL'
            }
          end

          it 'does not increment the counter' do
            expect { perform_request }.to change {
              http_router_rule_counter.get(rule_action: nil, rule_type: 'FIRST_CELL')
            }.by(0)
          end
        end
      end

      context 'when the headers are absent' do
        let(:headers) { {} }

        it 'does not increment the counter' do
          expect { perform_request }.to change {
            http_router_rule_counter.get(rule_action: nil, rule_type: nil)
          }.by(0)
        end
      end
    end
  end

  describe 'static context middleware', feature_category: :error_budgets do
    # to check the middleware tests, go to spec/lib/gitlab/middleware/static_context_middleware_spec.rb

    let(:expected_context) do
      { 'meta.feature_category' => 'groups_and_projects',
        'meta.caller_id' => 'Dashboard::GroupsController#index' }
    end

    context 'when action is successfully called' do
      it 'pushes static context to current context' do
        context = {}
        allow_next_instance_of(Dashboard::GroupsController) do |_controller|
          context.merge!(Gitlab::ApplicationContext.current.to_h)
        end

        get '/dashboard/groups' # randomly picked route

        expect(response).to have_gitlab_http_status(:found)
        expect(context).to include expected_context
      end
    end

    context 'when an exception is thrown before action' do
      it 'pushes static context to current context before controller callbacks' do
        context = {}
        unexpected_error = 'boom 💣💥'

        allow_next_instance_of(Dashboard::GroupsController) do |controller|
          # picking up a random before_action method to raise an "unexpected" exception
          allow(controller).to receive(:authenticate_user!).and_raise(unexpected_error)

          context.merge!(Gitlab::ApplicationContext.current.to_h)
        end

        expect { get '/dashboard/groups' }.to raise_error(unexpected_error)
        expect(context).to include expected_context
      end
    end

    context 'when controller overrides feature_category with nil' do
      it 'ignores nil feature category override' do
        context = {}

        allow_next_instance_of(Projects::NotesController) do |controller|
          # mimicking a bug overriding feature_category with nil
          allow(controller).to receive(:feature_category).and_return(nil)

          context.merge!(Gitlab::ApplicationContext.current.to_h)
        end

        project = create(:project, :public)
        project_snippet = create(:project_snippet, project: project)
        create(:note_on_project_snippet, project: project, noteable: project_snippet)
        # picking a route targeting a controller that overrides feature_category
        get project_noteable_notes_path(
          project,
          target_type: 'project_snippet',
          target_id: project_snippet.id,
          html: true
        )

        expect(context).to include({ 'meta.feature_category' => 'team_planning' })
      end
    end
  end
end
