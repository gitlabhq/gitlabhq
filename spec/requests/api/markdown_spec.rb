# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Markdown do
  describe "POST /markdown" do
    let(:user) {} # No-op. It gets overwritten in the contexts below.

    before do
      stub_commonmark_sourcepos_disabled

      post api("/markdown", user), params: params
    end

    shared_examples "rendered markdown text without GFM" do
      it "renders markdown text" do
        expect(response).to have_gitlab_http_status(:created)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response["html"]).to eq("<p>#{text}</p>")
      end
    end

    shared_examples "404 Project Not Found" do
      it "responses with 404 Not Found" do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response["message"]).to eq("404 Project Not Found")
      end
    end

    context "when arguments are invalid" do
      context "when text is missing" do
        let(:params) { {} }

        it "responses with 400 Bad Request" do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.headers["Content-Type"]).to eq("application/json")
          expect(json_response).to be_a(Hash)
          expect(json_response["error"]).to eq("text is missing")
        end
      end

      context "when project is not found" do
        let(:params) { { text: "Hello world!", gfm: true, project: "Dummy project" } }

        it_behaves_like "404 Project Not Found"
      end
    end

    context "when arguments are valid" do
      let_it_be(:project) { create(:project) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:issue_url) { "http://#{Gitlab.config.gitlab.host}/#{issue.project.namespace.path}/#{issue.project.path}/-/issues/#{issue.iid}" }
      let(:text) { ":tada: Hello world! :100: #{issue.to_reference}" }

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
            let(:user) { project.owner }

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
          let(:user) { project.owner }

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
            let(:user) { }

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
              expect(json_response["html"]).to include('Confidential title')
              expect(json_response["html"]).to include('Hello world!')
                                          .and include('data-name="tada"')
                                          .and include('data-name="100"')
                                          .and include("<a href=\"#{issue_url}\"")
                                          .and include("#1</a>")
            end
          end
        end
      end
    end
  end
end
