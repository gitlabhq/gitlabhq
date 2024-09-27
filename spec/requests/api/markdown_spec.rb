# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Markdown, feature_category: :markdown do
  describe "POST /markdown" do
    let(:user) {} # No-op. It gets overwritten in the contexts below.
    let(:token) {} # No-op. It gets overwritten in the contexts below.
    let(:disable_authenticate_markdown_api) { false }

    before do
      stub_commonmark_sourcepos_disabled
      stub_feature_flags(authenticate_markdown_api: false) if disable_authenticate_markdown_api

      if token
        post api("/markdown", personal_access_token: token), params: params
      else
        post api("/markdown", user), params: params
      end
    end

    shared_examples "rendered markdown text without GFM" do
      it "renders markdown text" do
        expect(response).to have_gitlab_http_status(:created)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response["html"]).to eq("<p>#{text}</p>")
      end
    end

    shared_examples '404 Project Not Found' do
      it 'responds with 404 Not Found' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    shared_examples '400 Bad Request' do
      it 'responds with 400 Bad Request' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.headers['Content-Type']).to eq('application/json')
        expect(json_response).to be_a(Hash)
        expect(json_response['error']).to eq('text is missing')
      end
    end

    context 'when not logged in' do
      let(:user) {}
      let(:params) { {} }

      context 'and authenticate_markdown_api turned on' do
        it 'responds with 401 Unathorized' do
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.headers['Content-Type']).to eq('application/json')
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('401 Unauthorized')
        end
      end

      context 'and authenticate_markdown_api turned off' do
        let(:disable_authenticate_markdown_api) { true }

        it_behaves_like '400 Bad Request'
      end
    end

    context 'when arguments are invalid' do
      let(:user) { create(:user) }

      context 'when text is missing' do
        let(:params) { {} }

        it_behaves_like '400 Bad Request'
      end

      context "when project is not found" do
        let(:params) { { text: "Hello world!", gfm: true, project: "Dummy project" } }

        it_behaves_like "404 Project Not Found"
      end
    end

    context "when arguments are valid" do
      let_it_be(:project) { create(:project) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:user) { create(:user) }
      let(:issue_url) { "http://#{Gitlab.config.gitlab.host}/#{issue.project.namespace.path}/#{issue.project.path}/-/issues/#{issue.iid}" }
      let(:text) { ":tada: Hello world! :100: #{issue.to_reference}" }

      context "when personal access token has only read_api scope" do
        let(:token) { create(:personal_access_token, user: user, scopes: [:read_api]) }
        let(:params) { { text: text } }

        it_behaves_like "rendered markdown text without GFM"
      end

      context "when not using gfm" do
        context "without project" do
          let(:params) { { text: text } }

          it_behaves_like "rendered markdown text without GFM"
        end

        context "with project" do
          let(:params) { { text: text, project: project.full_path } }

          context "when not authorized" do
            it_behaves_like "404 Project Not Found"
          end

          context "when authorized" do
            let(:user) { project.first_owner }

            it_behaves_like "rendered markdown text without GFM"
          end
        end
      end

      context "when using gfm" do
        context "without project" do
          let(:params) { { text: text, gfm: true } }

          it "renders markdown text" do
            expect(response).to have_gitlab_http_status(:created)
            expect(response.headers["Content-Type"]).to eq("application/json")
            expect(json_response).to be_a(Hash)
            expect(json_response["html"]).to include("Hello world!")
                                        .and include('data-name="tada"')
                                        .and include('data-name="100"')
                                        .and include("#1")
                                        .and exclude("<a href=\"#{issue_url}\"")
                                        .and exclude("#1</a>")
          end
        end

        context "with project" do
          let(:params) { { text: text, gfm: true, project: project.full_path } }
          let(:user) { project.first_owner }

          it "renders markdown text" do
            expect(response).to have_gitlab_http_status(:created)
            expect(response.headers["Content-Type"]).to eq("application/json")
            expect(json_response).to be_a(Hash)
            expect(json_response["html"]).to include("Hello world!")
                                        .and include('data-name="tada"')
                                        .and include('data-name="100"')
                                        .and include("<a href=\"#{issue_url}\"")
                                        .and include("#1</a>")
          end
        end

        context 'with a public project and confidential issue' do
          let(:public_project) { create(:project, :public) }
          let(:issue) { create(:issue, :confidential, project: public_project, title: 'Confidential title') }

          let(:text)   { ":tada: Hello world! :100: #{issue.to_reference}" }
          let(:params) { { text: text, gfm: true, project: public_project.full_path } }

          shared_examples 'user without proper access' do
            it 'does not render the title or link' do
              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["html"]).not_to include('Confidential title')
              expect(json_response["html"]).not_to include('<a href=')
              expect(json_response["html"]).to include('Hello world!')
                                          .and include('data-name="tada"')
                                          .and include('data-name="100"')
                                          .and include('#1</p>')
            end
          end

          context 'when not logged in' do
            let(:user) {}
            let(:disable_authenticate_markdown_api) { true }

            it_behaves_like 'user without proper access'
          end

          context 'when logged in as user without access' do
            it_behaves_like 'user without proper access'
          end

          context 'when logged in as author' do
            let(:user) { issue.author }

            it 'renders the title or link' do
              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["html"]).to include('Confidential title')
              expect(json_response["html"]).to include('Hello world!')
                                          .and include('data-name="tada"')
                                          .and include('data-name="100"')
                                          .and include("<a href=\"#{issue_url}\"")
                                          .and include("#1</a>")
            end
          end
        end

        context 'with a public project and issues only for team members' do
          let(:public_project) do
            create(:project, :public).tap do |project|
              project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)
            end
          end

          let(:issue)  { create(:issue, project: public_project, title: 'Team only title') }
          let(:text)   { issue.to_reference.to_s }
          let(:params) { { text: text, gfm: true, project: public_project.full_path } }

          shared_examples 'user without proper access' do
            it 'does not render the title' do
              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["html"]).not_to include('Team only title')
            end
          end

          context 'when not logged in and authenticate_markdown_api turned off' do
            let(:user) {}
            let(:disable_authenticate_markdown_api) { true }

            it_behaves_like 'user without proper access'
          end

          context 'when logged in as user without access' do
            let(:user) { create(:user) }

            it_behaves_like 'user without proper access'
          end

          context 'when logged in as author' do
            let(:user) { issue.author }

            it 'renders the title or link' do
              expect(response).to have_gitlab_http_status(:created)
              expect(json_response["html"]).to include('Team only title')
            end
          end
        end
      end
    end
  end
end
