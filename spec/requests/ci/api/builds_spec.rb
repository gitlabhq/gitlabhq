require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:runner) { FactoryGirl.create(:ci_runner, tag_list: ["mysql", "ruby"]) }
  let(:project) { FactoryGirl.create(:ci_project) }
  let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }

  before do
    stub_ci_commit_to_return_yaml_file
  end

  describe "Builds API for runners" do
    let(:shared_runner) { FactoryGirl.create(:ci_runner, token: "SharedRunner") }
    let(:shared_project) { FactoryGirl.create(:ci_project, name: "SharedProject") }
    let(:shared_gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: shared_project) }

    before do
      FactoryGirl.create :ci_runner_project, project_id: project.id, runner_id: runner.id
    end

    describe "POST /builds/register" do
      it "should start a build" do
        commit = FactoryGirl.create(:ci_commit, gl_project: gl_project)
        commit.create_builds('master', false, nil)
        build = commit.builds.first

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response['sha']).to eq(build.sha)
        expect(runner.reload.platform).to eq("darwin")
      end

      it "should return 404 error if no pending build found" do
        post ci_api("/builds/register"), token: runner.token

        expect(response.status).to eq(404)
      end

      it "should return 404 error if no builds for specific runner" do
        commit = FactoryGirl.create(:ci_commit, gl_project: shared_gl_project)
        FactoryGirl.create(:ci_build, commit: commit, status: 'pending')

        post ci_api("/builds/register"), token: runner.token

        expect(response.status).to eq(404)
      end

      it "should return 404 error if no builds for shared runner" do
        commit = FactoryGirl.create(:ci_commit, gl_project: gl_project)
        FactoryGirl.create(:ci_build, commit: commit, status: 'pending')

        post ci_api("/builds/register"), token: shared_runner.token

        expect(response.status).to eq(404)
      end

      it "returns options" do
        commit = FactoryGirl.create(:ci_commit, gl_project: gl_project)
        commit.create_builds('master', false, nil)

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["options"]).to eq({ "image" => "ruby:2.1", "services" => ["postgres"] })
      end

      it "returns variables" do
        commit = FactoryGirl.create(:ci_commit, gl_project: gl_project)
        commit.create_builds('master', false, nil)
        project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["variables"]).to eq([
          { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
          { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
          { "key" => "CI_BUILD_ARTIFACTS_UPLOAD_URL", "value" => "http://localhost/ci/api/v1/builds/#{json_response['id']}/artifacts?token=#{project.token}", "public" => false },
          { "key" => "DB_NAME", "value" => "postgres", "public" => true },
          { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false }
        ])
      end

      it "returns variables for triggers" do
        trigger = FactoryGirl.create(:ci_trigger, project: project)
        commit = FactoryGirl.create(:ci_commit, gl_project: gl_project)

        trigger_request = FactoryGirl.create(:ci_trigger_request_with_variables, commit: commit, trigger: trigger)
        commit.create_builds('master', false, nil, trigger_request)
        project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["variables"]).to eq([
          { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
          { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
          { "key" => "CI_BUILD_ARTIFACTS_UPLOAD_URL", "value" => "http://localhost/ci/api/v1/builds/#{json_response['id']}/artifacts?token=#{project.token}", "public" => false },
          { "key" => "CI_BUILD_TRIGGERED", "value" => "true", "public" => true },
          { "key" => "DB_NAME", "value" => "postgres", "public" => true },
          { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false },
          { "key" => "TRIGGER_KEY", "value" => "TRIGGER_VALUE", "public" => false },
        ])
      end
    end

    describe "PUT /builds/:id" do
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project)}
      let(:build) { FactoryGirl.create(:ci_build, commit: commit, runner_id: runner.id) }

      it "should update a running build" do
        build.run!
        put ci_api("/builds/#{build.id}"), token: runner.token
        expect(response.status).to eq(200)
      end

      it 'Should not override trace information when no trace is given' do
        build.run!
        build.update!(trace: 'hello_world')
        put ci_api("/builds/#{build.id}"), token: runner.token
        expect(build.reload.trace).to eq 'hello_world'
      end
    end

    context "Artifacts" do
      let(:file_upload) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/gif') }
      let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project) }
      let(:build) { FactoryGirl.create(:ci_build, commit: commit, runner_id: runner.id) }
      let(:post_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:delete_url) { ci_api("/builds/#{build.id}/artifact") }
      let(:get_url) { ci_api("/builds/#{build.id}/artifact") }

      describe "POST /builds/:id/artifacts" do
        context "should post artifact to running build" do
          before do
            build.run!
          end

          it "using Unicorn" do
            post post_url, token: build.project.token, file: file_upload
            expect(response.status).to eq(201)
            expect(json_response["artifact_file"]["filename"]).to eq(file_upload.original_filename)
          end

          it "using Nginx Upload Module" do
            post post_url, token: build.project.token,
                           "file.name" => file_upload.original_filename,
                           "file.path" => file_upload.path,
                           "file.type" => file_upload.content_type
            expect(response.status).to eq(201)
            expect(json_response["artifact_file"]["filename"]).to eq(file_upload.original_filename)
          end

          it "updates artifact" do
            post post_url, token: build.project.token, file: file_upload
            post post_url, token: build.project.token, file: file_upload2
            expect(response.status).to eq(201)
            expect(json_response["artifact_file"]["filename"]).to eq(file_upload2.original_filename)
          end
        end

        context "should fail to post to large artifact" do
          before do
            build.run!
          end

          it do
            settings = Ci::ApplicationSetting.create_from_defaults
            settings.update_attributes(max_artifact_size: 0)
            post post_url, token: build.project.token, file: file_upload
            expect(response.status).to eq(413)
          end
        end
      end

      describe "DELETE /builds/:id/artifact" do
        before do
          build.run!
          post post_url, token: build.project.token, file: file_upload
        end

        it "should delete artifact build" do
          build.success
          delete delete_url, token: build.project.token
          expect(response.status).to eq(200)
        end
      end

      describe "GET /builds/:id/artifact" do
        before do
          build.run!
        end

        it "should download artifact" do
          post post_url, token: build.project.token, file: file_upload
          get get_url, token: build.project.token
          expect(response.status).to eq(200)
        end

        it "should fail to download if no artifact uploaded" do
          get get_url, token: build.project.token
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
