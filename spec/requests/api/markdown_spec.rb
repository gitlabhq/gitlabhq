require "spec_helper"

describe API::Markdown do
  RSpec::Matchers.define_negated_matcher :exclude, :include

  describe "POST /markdown" do
    let(:user) {} # No-op. It gets overwritten in the contexts below.

    before do
      post api("/markdown", user), params
    end

    shared_examples "rendered markdown text without GFM" do
      it "renders markdown text" do
        expect(response).to have_http_status(201)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response["html"]).to eq("<p>#{text}</p>")
      end
    end

    shared_examples "404 Project Not Found" do
      it "responses with 404 Not Found" do
        expect(response).to have_http_status(404)
        expect(response.headers["Content-Type"]).to eq("application/json")
        expect(json_response).to be_a(Hash)
        expect(json_response["message"]).to eq("404 Project Not Found")
      end
    end

    context "when arguments are invalid" do
      context "when text is missing" do
        let(:params) { {} }

        it "responses with 400 Bad Request" do
          expect(response).to have_http_status(400)
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
      set(:project) { create(:project) }
      set(:issue) { create(:issue, project: project) }
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
            expect(response).to have_http_status(201)
            expect(response.headers["Content-Type"]).to eq("application/json")
            expect(json_response).to be_a(Hash)
            expect(json_response["html"]).to include("Hello world!")
                                        .and include('data-name="tada"')
                                        .and include('data-name="100"')
                                        .and include("#1")
                                        .and exclude("<a href=\"#{IssuesHelper.url_for_issue(issue.iid, project)}\"")
                                        .and exclude("#1</a>")
          end
        end

        context "with project" do
          let(:params) { { text: text, gfm: true, project: project.full_path } }
          let(:user) { project.owner }

          it "renders markdown text" do
            expect(response).to have_http_status(201)
            expect(response.headers["Content-Type"]).to eq("application/json")
            expect(json_response).to be_a(Hash)
            expect(json_response["html"]).to include("Hello world!")
                                        .and include('data-name="tada"')
                                        .and include('data-name="100"')
                                        .and include("<a href=\"#{IssuesHelper.url_for_issue(issue.iid, project)}\"")
                                        .and include("#1</a>")
          end
        end
      end
    end
  end
end
