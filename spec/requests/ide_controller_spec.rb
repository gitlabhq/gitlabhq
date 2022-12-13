# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeController, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:reporter) { create(:user) }

  let_it_be(:project) do
    create(:project, :private).tap do |p|
      p.add_reporter(reporter)
    end
  end

  let_it_be(:creator) { project.creator }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:top_nav_partial) { 'layouts/header/_default' }

  let(:user) { creator }
  let(:branch) { '' }

  def find_csp_frame_src
    csp = response.headers['Content-Security-Policy']

    # Transform "frame-src foo bar; connect-src foo bar; script-src ..."
    # into array of connect-src values
    csp.split(';')
      .map(&:strip)
      .find { |entry| entry.starts_with?('frame-src') }
      .split(' ')
      .drop(1)
  end

  before do
    stub_feature_flags(vscode_web_ide: true)
    sign_in(user)
  end

  describe '#index', :aggregate_failures do
    subject { get route }

    shared_examples 'user access rights check' do
      context 'user can read project' do
        it 'increases the views counter' do
          expect(Gitlab::UsageDataCounters::WebIdeCounter).to receive(:increment_views_count)

          subject
        end

        context 'user can read project but cannot push code' do
          include ProjectForksHelper

          let(:user) { reporter }

          context 'when user does not have fork' do
            it 'instantiates fork_info instance var with fork_path and returns 200' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:project)).to eq project
              expect(assigns(:fork_info)).to eq({ fork_path: controller.helpers.ide_fork_and_edit_path(project, branch, '', with_notice: false) })
            end

            it 'has nil fork_info if user cannot fork' do
              project.project_feature.update!(forking_access_level: ProjectFeature::DISABLED)

              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:fork_info)).to be_nil
            end
          end

          context 'when user has fork' do
            let!(:fork) { fork_project(project, user, repository: true, namespace: user.namespace) }

            it 'instantiates fork_info instance var with ide_path and returns 200' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:project)).to eq project
              expect(assigns(:fork_info)).to eq({ ide_path: controller.helpers.ide_edit_path(fork, branch, '') })
            end
          end
        end
      end

      context 'user cannot read project' do
        let(:user) { other_user }

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context '/-/ide' do
      let(:route) { '/-/ide' }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context '/-/ide/project' do
      let(:route) { '/-/ide/project' }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context '/-/ide/project/:project' do
      let(:route) { "/-/ide/project/#{project.full_path}" }

      it 'instantiates project instance var and returns 200' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:project)).to eq project
        expect(assigns(:branch)).to be_nil
        expect(assigns(:path)).to be_nil
        expect(assigns(:merge_request)).to be_nil
        expect(assigns(:fork_info)).to be_nil
      end

      it_behaves_like 'user access rights check'

      %w(edit blob tree).each do |action|
        context "/-/ide/project/:project/#{action}" do
          let(:route) { "/-/ide/project/#{project.full_path}/#{action}" }

          it 'instantiates project instance var and returns 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:project)).to eq project
            expect(assigns(:branch)).to be_nil
            expect(assigns(:path)).to be_nil
            expect(assigns(:merge_request)).to be_nil
            expect(assigns(:fork_info)).to be_nil
          end

          it_behaves_like 'user access rights check'

          context "/-/ide/project/:project/#{action}/:branch" do
            let(:branch) { 'master' }
            let(:route) { "/-/ide/project/#{project.full_path}/#{action}/#{branch}" }

            it 'instantiates project and branch instance vars and returns 200' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:project)).to eq project
              expect(assigns(:branch)).to eq branch
              expect(assigns(:path)).to be_nil
              expect(assigns(:merge_request)).to be_nil
              expect(assigns(:fork_info)).to be_nil
            end

            it_behaves_like 'user access rights check'

            context "/-/ide/project/:project/#{action}/:branch/-" do
              let(:branch) { 'branch/slash' }
              let(:route) { "/-/ide/project/#{project.full_path}/#{action}/#{branch}/-" }

              it 'instantiates project and branch instance vars and returns 200' do
                subject

                expect(response).to have_gitlab_http_status(:ok)
                expect(assigns(:project)).to eq project
                expect(assigns(:branch)).to eq branch
                expect(assigns(:path)).to be_nil
                expect(assigns(:merge_request)).to be_nil
                expect(assigns(:fork_info)).to be_nil
              end

              it_behaves_like 'user access rights check'

              context "/-/ide/project/:project/#{action}/:branch/-/:path" do
                let(:branch) { 'master' }
                let(:route) { "/-/ide/project/#{project.full_path}/#{action}/#{branch}/-/foo/.bar" }

                it 'instantiates project, branch, and path instance vars and returns 200' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(assigns(:project)).to eq project
                  expect(assigns(:branch)).to eq branch
                  expect(assigns(:path)).to eq 'foo/.bar'
                  expect(assigns(:merge_request)).to be_nil
                  expect(assigns(:fork_info)).to be_nil
                end

                it_behaves_like 'user access rights check'
              end
            end
          end
        end
      end

      context '/-/ide/project/:project/merge_requests/:merge_request_id' do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

        let(:route) { "/-/ide/project/#{project.full_path}/merge_requests/#{merge_request.id}" }

        it 'instantiates project and merge_request instance vars and returns 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:project)).to eq project
          expect(assigns(:branch)).to be_nil
          expect(assigns(:path)).to be_nil
          expect(assigns(:merge_request)).to eq merge_request.id.to_s
          expect(assigns(:fork_info)).to be_nil
        end

        it_behaves_like 'user access rights check'
      end

      describe 'Snowplow view event', :snowplow do
        it 'is tracked' do
          subject

          expect_snowplow_event(
            category: described_class.to_s,
            action: 'web_ide_views',
            namespace: project.namespace,
            user: user
          )
        end

        context 'when route_hll_to_snowplow_phase2 FF is disabled' do
          before do
            stub_feature_flags(route_hll_to_snowplow_phase2: false)
          end

          it 'does not track Snowplow event' do
            subject

            expect_no_snowplow_event
          end
        end
      end

      # This indirectly tests that `minimal: true` was passed to the fullscreen layout
      describe 'layout' do
        where(:ff_state, :use_legacy_web_ide, :expect_top_nav) do
          false | false | true
          false | true  | true
          true  | true  | true
          true  | false | false
        end

        with_them do
          before do
            stub_feature_flags(vscode_web_ide: ff_state)
            allow(user).to receive(:use_legacy_web_ide).and_return(use_legacy_web_ide)

            subject
          end

          it 'handles rendering top nav' do
            if expect_top_nav
              expect(response).to render_template(top_nav_partial)
            else
              expect(response).not_to render_template(top_nav_partial)
            end
          end
        end
      end
    end

    describe 'frame-src content security policy' do
      let(:route) { '/-/ide' }

      before do
        subject
      end

      it 'adds https://*.vscode-cdn.net in frame-src CSP policy' do
        expect(find_csp_frame_src).to include("https://*.vscode-cdn.net/")
      end
    end

    describe 'when vscode_web_ide feature flag is disabled' do
      describe 'frame-src content security policy' do
        let(:route) { '/-/ide' }

        before do
          stub_feature_flags(vscode_web_ide: false)
          subject
        end

        it 'does not add https://*.vscode-cdn.net in frame-src CSP policy' do
          expect(find_csp_frame_src).not_to include("https://*.vscode-cdn.net/")
        end
      end
    end
  end
end
