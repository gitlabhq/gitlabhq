require "spec_helper"

describe API::Markdown do
  describe "POST /markdown" do
    before do
      post api("/markdown"), params
    end

    shared_examples "400 Bad Request" do
      it "responses with 400 Bad Request" do
        expect(response).to have_http_status(400)
        expect(json_response).to be_a(Hash)
        expect(json_response["error"]).to eq(error_message)
      end
    end

    context "when arguments are invalid" do
      context "when text is missing" do
        let(:error_message) { "text is missing" }
        let(:params) { {} }

        it_behaves_like "400 Bad Request"
      end

      context "when gfm is missing" do
        let(:error_message) { "gfm, project provide all or none of parameters" }
        let(:params) { { text: "Hello world!", project: "Dummy project" } }

        it_behaves_like "400 Bad Request"
      end

      context "when project is missing" do
        let(:error_message) { "gfm, project provide all or none of parameters" }
        let(:params) { { text: "Hello world!", gfm: true } }

        it_behaves_like "400 Bad Request"
      end
    end

    context "when arguments are valid" do
      set(:project) { create(:project) }
      set(:issue) { create(:issue, project: project) }
      let(:text) { ":tada: Hello world! :100: #{issue.to_reference}" }

      context "when not using gfm" do
        let(:params) { { text: text } }

        it "renders markdown text" do
          expect(response).to have_http_status(201)
          expect(response.body).to eq("<p>#{text}</p>")
        end
      end

      context "when using gfm" do
        let(:params) { { text: text, gfm: true, project: project.full_path } }

        it "renders markdown text" do
          expect(response).to have_http_status(201)
          expect(response.body).to include("Hello world!")
                              .and include("🎉")
                              .and include("💯")
                              .and include("<a href=\"/#{project.full_path}/issues/#{issue.iid}\"")
                              .and include("#1</a>")
        end
      end
    end
  end
end
