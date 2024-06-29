# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MarkdownUploads, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:user) { create(:user, guest_of: project) }

  describe "POST /projects/:id/uploads/authorize" do
    include WorkhorseHelpers

    let(:headers) { workhorse_internal_api_request_header.merge({ 'HTTP_GITLAB_WORKHORSE' => 1 }) }
    let(:path) { "/projects/#{project.id}/uploads/authorize" }

    context 'with authorized user' do
      it "returns 200" do
        post api(path, user), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['MaximumSize']).to eq(project.max_attachment_size)
      end
    end

    context 'with unauthorized user' do
      it "returns 404" do
        post api(path, create(:user)), headers: headers

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no Workhorse headers' do
      it "returns 403" do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "POST /projects/:id/uploads" do
    let(:file) { fixture_file_upload("spec/fixtures/dk.png", "image/png") }
    let(:path) { "/projects/#{project.id}/uploads" }

    before do
      project
    end

    it "uploads the file and returns its info" do
      post api(path, user), params: { file: file }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['alt']).to eq("dk")
      expect(json_response['url']).to start_with("/uploads/")
      expect(json_response['url']).to end_with("/dk.png")
      expect(json_response['full_path']).to start_with("/-/project/#{project.id}/uploads")
    end

    it "does not leave the temporary file in place after uploading, even when the tempfile reaper does not run" do
      tempfile = Tempfile.new('foo')
      path = tempfile.path

      # rubocop: disable RSpec/AnyInstanceOf -- allow_next_instance_of does not work here because TempfileReaper is a middleware that is initialized early
      allow_any_instance_of(Rack::TempfileReaper).to receive(:call) do |instance, env|
        instance.instance_variable_get(:@app).call(env)
      end
      # rubocop: enable RSpec/AnyInstanceOf

      expect(path).not_to be(nil)
      expect(Rack::Multipart::Parser::TEMPFILE_FACTORY).to receive(:call).and_return(tempfile)

      post api(path, user), params: { file: fixture_file_upload("spec/fixtures/dk.png", "image/png") }

      expect(tempfile.path).to be(nil)
      expect(File.exist?(path)).to be(false)
    end
  end
end
