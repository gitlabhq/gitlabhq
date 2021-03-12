# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeController do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:creator) { project.creator }
  let_it_be(:other_user) { create(:user) }

  let(:user) { creator }

  before do
    sign_in(user)
  end

  it 'increases the views counter' do
    expect(Gitlab::UsageDataCounters::WebIdeCounter).to receive(:increment_views_count)

    get ide_url
  end

  describe '#index', :aggregate_failures do
    subject { get route }

    shared_examples 'user cannot push code' do
      include ProjectForksHelper

      let(:user) { other_user }

      context 'when user does not have fork' do
        it 'does not instantiate forked_project instance var and return 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:project)).to eq project
          expect(assigns(:forked_project)).to be_nil
        end
      end

      context 'when user has have fork' do
        let!(:fork) { fork_project(project, user, repository: true) }

        it 'instantiates forked_project instance var and return 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:project)).to eq project
          expect(assigns(:forked_project)).to eq fork
        end
      end
    end

    context '/-/ide' do
      let(:route) { '/-/ide' }

      it 'does not instantiate any instance var and return 200' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:project)).to be_nil
        expect(assigns(:branch)).to be_nil
        expect(assigns(:path)).to be_nil
        expect(assigns(:merge_request)).to be_nil
        expect(assigns(:forked_project)).to be_nil
      end
    end

    context '/-/ide/project' do
      let(:route) { '/-/ide/project' }

      it 'does not instantiate any instance var and return 200' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:project)).to be_nil
        expect(assigns(:branch)).to be_nil
        expect(assigns(:path)).to be_nil
        expect(assigns(:merge_request)).to be_nil
        expect(assigns(:forked_project)).to be_nil
      end
    end

    context '/-/ide/project/:project' do
      let(:route) { "/-/ide/project/#{project.full_path}" }

      it 'instantiates project instance var and return 200' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:project)).to eq project
        expect(assigns(:branch)).to be_nil
        expect(assigns(:path)).to be_nil
        expect(assigns(:merge_request)).to be_nil
        expect(assigns(:forked_project)).to be_nil
      end

      it_behaves_like 'user cannot push code'

      %w(edit blob tree).each do |action|
        context "/-/ide/project/:project/#{action}" do
          let(:route) { "/-/ide/project/#{project.full_path}/#{action}" }

          it 'instantiates project instance var and return 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:project)).to eq project
            expect(assigns(:branch)).to be_nil
            expect(assigns(:path)).to be_nil
            expect(assigns(:merge_request)).to be_nil
            expect(assigns(:forked_project)).to be_nil
          end

          it_behaves_like 'user cannot push code'

          context "/-/ide/project/:project/#{action}/:branch" do
            let(:route) { "/-/ide/project/#{project.full_path}/#{action}/master" }

            it 'instantiates project and branch instance vars and return 200' do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:project)).to eq project
              expect(assigns(:branch)).to eq 'master'
              expect(assigns(:path)).to be_nil
              expect(assigns(:merge_request)).to be_nil
              expect(assigns(:forked_project)).to be_nil
            end

            it_behaves_like 'user cannot push code'

            context "/-/ide/project/:project/#{action}/:branch/-" do
              let(:route) { "/-/ide/project/#{project.full_path}/#{action}/branch/slash/-" }

              it 'instantiates project and branch instance vars and return 200' do
                subject

                expect(response).to have_gitlab_http_status(:ok)
                expect(assigns(:project)).to eq project
                expect(assigns(:branch)).to eq 'branch/slash'
                expect(assigns(:path)).to be_nil
                expect(assigns(:merge_request)).to be_nil
                expect(assigns(:forked_project)).to be_nil
              end

              it_behaves_like 'user cannot push code'

              context "/-/ide/project/:project/#{action}/:branch/-/:path" do
                let(:route) { "/-/ide/project/#{project.full_path}/#{action}/master/-/foo/.bar" }

                it 'instantiates project, branch, and path instance vars and return 200' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(assigns(:project)).to eq project
                  expect(assigns(:branch)).to eq 'master'
                  expect(assigns(:path)).to eq 'foo/.bar'
                  expect(assigns(:merge_request)).to be_nil
                  expect(assigns(:forked_project)).to be_nil
                end

                it_behaves_like 'user cannot push code'
              end
            end
          end
        end
      end

      context '/-/ide/project/:project/merge_requests/:merge_request_id' do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

        let(:route) { "/-/ide/project/#{project.full_path}/merge_requests/#{merge_request.id}" }

        it 'instantiates project and merge_request instance vars and return 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:project)).to eq project
          expect(assigns(:branch)).to be_nil
          expect(assigns(:path)).to be_nil
          expect(assigns(:merge_request)).to eq merge_request.id.to_s
          expect(assigns(:forked_project)).to be_nil
        end

        it_behaves_like 'user cannot push code'
      end
    end
  end
end
