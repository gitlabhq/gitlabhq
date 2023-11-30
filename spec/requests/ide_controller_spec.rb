# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeController, feature_category: :web_ide do
  include ContentSecurityPolicyHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:reporter) { create(:user) }

  let_it_be(:project) do
    create(:project, :private).tap do |p|
      p.add_reporter(reporter)
    end
  end

  let_it_be(:creator) { project.creator }
  let_it_be(:other_user) { create(:user) }

  let(:user) { creator }

  before do
    stub_feature_flags(vscode_web_ide: true)
    sign_in(user)
  end

  describe '#index', :aggregate_failures do
    subject { get route }

    shared_examples 'user access rights check' do
      context 'when user can read project' do
        it 'increases the views counter' do
          expect(Gitlab::UsageDataCounters::WebIdeCounter).to receive(:increment_views_count)

          subject
        end

        context 'when user can read project but cannot push code' do
          include ProjectForksHelper

          let(:user) { reporter }

          context 'when user does not have fork' do
            it 'instantiates fork_info instance var with fork_path and returns 200' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:project)).to eq project

              expect(assigns(:fork_info)).to eq({
                fork_path: controller.helpers.ide_fork_and_edit_path(
                  project,
                  '',
                  '',
                  with_notice: false
                )
              })
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
              expect(assigns(:fork_info)).to eq({ ide_path: controller.helpers.ide_edit_path(fork, '', '') })
            end
          end
        end
      end

      context 'when user cannot read project' do
        let(:user) { other_user }

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with /-/ide' do
      let(:route) { '/-/ide' }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with /-/ide/project' do
      let(:route) { '/-/ide/project' }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with /-/ide/project/:project' do
      let(:route) { "/-/ide/project/#{project.full_path}" }

      it 'instantiates project instance var and returns 200' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:project)).to eq project
        expect(assigns(:fork_info)).to be_nil
      end

      it_behaves_like 'user access rights check'

      %w[edit blob tree].each do |action|
        context "with /-/ide/project/:project/#{action}" do
          let(:route) { "/-/ide/project/#{project.full_path}/#{action}" }

          it 'instantiates project instance var and returns 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:project)).to eq project
            expect(assigns(:fork_info)).to be_nil
          end

          it_behaves_like 'user access rights check'
        end
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
      end

      describe 'legacy Web IDE' do
        before do
          stub_feature_flags(vscode_web_ide: false)
        end

        it 'uses application layout' do
          subject

          expect(response).to render_template('layouts/application')
        end
      end

      describe 'vscode IDE' do
        before do
          stub_feature_flags(vscode_web_ide: true)
        end

        it 'uses fullscreen layout' do
          subject

          expect(response).to render_template('layouts/fullscreen')
        end
      end
    end

    describe 'content security policy' do
      let(:route) { '/-/ide' }

      it 'updates the content security policy with the correct frame sources' do
        subject

        expect(find_csp_directive('frame-src')).to include("http://www.example.com/assets/webpack/", "https://*.web-ide.gitlab-static.net/")
        expect(find_csp_directive('worker-src')).to include("http://www.example.com/assets/webpack/")
      end

      it 'with relative_url_root, updates the content security policy with the correct frame sources' do
        stub_config_setting(relative_url_root: '/gitlab')

        subject

        expect(find_csp_directive('frame-src')).to include("http://www.example.com/gitlab/assets/webpack/")
        expect(find_csp_directive('worker-src')).to include("http://www.example.com/gitlab/assets/webpack/")
      end
    end
  end
end
