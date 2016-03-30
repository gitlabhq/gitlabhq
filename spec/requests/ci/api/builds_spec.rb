require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:runner) { FactoryGirl.create(:ci_runner, tag_list: ["mysql", "ruby"]) }
  let(:project) { FactoryGirl.create(:empty_project) }

  before do
    stub_ci_commit_to_return_yaml_file
  end

  describe "Builds API for runners" do
    let(:shared_runner) { FactoryGirl.create(:ci_runner, token: "SharedRunner") }
    let(:shared_project) { FactoryGirl.create(:empty_project, name: "SharedProject") }

    before do
      FactoryGirl.create :ci_runner_project, project: project, runner: runner
    end

    describe "POST /builds/register" do
      it "should start a build" do
        commit = FactoryGirl.create(:ci_commit, project: project)
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
        commit = FactoryGirl.create(:ci_commit, project: shared_project)
        FactoryGirl.create(:ci_build, commit: commit, status: 'pending')

        post ci_api("/builds/register"), token: runner.token

        expect(response.status).to eq(404)
      end

      it "should return 404 error if no builds for shared runner" do
        commit = FactoryGirl.create(:ci_commit, project: project)
        FactoryGirl.create(:ci_build, commit: commit, status: 'pending')

        post ci_api("/builds/register"), token: shared_runner.token

        expect(response.status).to eq(404)
      end

      it "returns options" do
        commit = FactoryGirl.create(:ci_commit, project: project)
        commit.create_builds('master', false, nil)

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["options"]).to eq({ "image" => "ruby:2.1", "services" => ["postgres"] })
      end

      it "returns variables" do
        commit = FactoryGirl.create(:ci_commit, project: project)
        commit.create_builds('master', false, nil)
        project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["variables"]).to eq([
          { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
          { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
          { "key" => "DB_NAME", "value" => "postgres", "public" => true },
          { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false }
        ])
      end

      it "returns variables for triggers" do
        trigger = FactoryGirl.create(:ci_trigger, project: project)
        commit = FactoryGirl.create(:ci_commit, project: project)

        trigger_request = FactoryGirl.create(:ci_trigger_request_with_variables, commit: commit, trigger: trigger)
        commit.create_builds('master', false, nil, trigger_request)
        project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["variables"]).to eq([
          { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
          { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
          { "key" => "CI_BUILD_TRIGGERED", "value" => "true", "public" => true },
          { "key" => "DB_NAME", "value" => "postgres", "public" => true },
          { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false },
          { "key" => "TRIGGER_KEY", "value" => "TRIGGER_VALUE", "public" => false },
        ])
      end

      it "returns dependent builds" do
        commit = FactoryGirl.create(:ci_commit, project: project)
        commit.create_builds('master', false, nil, nil)
        commit.builds.where(stage: 'test').each(&:success)

        post ci_api("/builds/register"), token: runner.token, info: { platform: :darwin }

        expect(response.status).to eq(201)
        expect(json_response["depends_on_builds"].count).to eq(2)
        expect(json_response["depends_on_builds"][0]["name"]).to eq("rspec")
      end

      %w(name version revision platform architecture).each do |param|
        context "updates runner #{param}" do
          let(:value) { "#{param}_value" }

          subject { runner.read_attribute(param.to_sym) }

          it do
            post ci_api("/builds/register"), token: runner.token, info: { param => value }
            expect(response.status).to eq(404)
            runner.reload
            is_expected.to eq(value)
          end
        end
      end
    end

    describe "PUT /builds/:id" do
      let(:commit) {create(:ci_commit, project: project)}
      let(:build) { create(:ci_build, :trace, commit: commit, runner_id: runner.id) }

      before do
        build.run!
        put ci_api("/builds/#{build.id}"), token: runner.token
      end

      it "should update a running build" do
        expect(response.status).to eq(200)
      end

      it 'should not override trace information when no trace is given' do
        expect(build.reload.trace).to eq 'BUILD TRACE'
      end

      context 'build has been erased' do
        let(:build) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it 'should respond with forbidden' do
          expect(response.status).to eq 403
        end
      end
    end

    context "Artifacts" do
      let(:file_upload) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/gif') }
      let(:commit) { create(:ci_commit, project: project) }
      let(:build) { create(:ci_build, commit: commit, runner_id: runner.id) }
      let(:authorize_url) { ci_api("/builds/#{build.id}/artifacts/authorize") }
      let(:post_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:delete_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:get_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:headers) { { "GitLab-Workhorse" => "1.0" } }
      let(:headers_with_token) { headers.merge(Ci::API::Helpers::BUILD_TOKEN_HEADER => build.token) }

      before { build.run! }

      describe "POST /builds/:id/artifacts/authorize" do
        context "should authorize posting artifact to running build" do
          it "using token as parameter" do
            post authorize_url, { token: build.token }, headers
            expect(response.status).to eq(200)
            expect(json_response["TempPath"]).to_not be_nil
          end

          it "using token as header" do
            post authorize_url, {}, headers_with_token
            expect(response.status).to eq(200)
            expect(json_response["TempPath"]).to_not be_nil
          end
        end

        context "should fail to post too large artifact" do
          it "using token as parameter" do
            stub_application_setting(max_artifacts_size: 0)
            post authorize_url, { token: build.token, filesize: 100 }, headers
            expect(response.status).to eq(413)
          end

          it "using token as header" do
            stub_application_setting(max_artifacts_size: 0)
            post authorize_url, { filesize: 100 }, headers_with_token
            expect(response.status).to eq(413)
          end
        end

        context 'authorization token is invalid' do
          before { post authorize_url, { token: 'invalid', filesize: 100 } }

          it 'should respond with forbidden' do
            expect(response.status).to eq(403)
          end
        end
      end

      describe "POST /builds/:id/artifacts" do
        context "disable sanitizer" do
          before do
            # by configuring this path we allow to pass temp file from any path
            allow(ArtifactUploader).to receive(:artifacts_upload_path).and_return('/')
          end

          context 'build has been erased' do
            let(:build) { create(:ci_build, erased_at: Time.now) }
            before { upload_artifacts(file_upload, headers_with_token) }

            it 'should respond with forbidden' do
              expect(response.status).to eq 403
            end
          end

          context "should post artifact to running build" do
            it "uses regual file post" do
              upload_artifacts(file_upload, headers_with_token, false)
              expect(response.status).to eq(201)
              expect(json_response["artifacts_file"]["filename"]).to eq(file_upload.original_filename)
            end

            it "uses accelerated file post" do
              upload_artifacts(file_upload, headers_with_token, true)
              expect(response.status).to eq(201)
              expect(json_response["artifacts_file"]["filename"]).to eq(file_upload.original_filename)
            end

            it "updates artifact" do
              upload_artifacts(file_upload, headers_with_token)
              upload_artifacts(file_upload2, headers_with_token)
              expect(response.status).to eq(201)
              expect(json_response["artifacts_file"]["filename"]).to eq(file_upload2.original_filename)
            end
          end

          context 'should post artifacts file and metadata file' do
            let!(:artifacts) { file_upload }
            let!(:metadata) { file_upload2 }

            let(:stored_artifacts_file) { build.reload.artifacts_file.file }
            let(:stored_metadata_file) { build.reload.artifacts_metadata.file }

            before do
              post(post_url, post_data, headers_with_token)
            end

            context 'post data accelerated by workhorse is correct' do
              let(:post_data) do
                { 'file.path' => artifacts.path,
                  'file.name' => artifacts.original_filename,
                  'metadata.path' => metadata.path,
                  'metadata.name' => metadata.original_filename }
              end

              it 'stores artifacts and artifacts metadata' do
                expect(response.status).to eq(201)
                expect(stored_artifacts_file.original_filename).to eq(artifacts.original_filename)
                expect(stored_metadata_file.original_filename).to eq(metadata.original_filename)
              end
            end

            context 'no artifacts file in post data' do
              let(:post_data) do
                { 'metadata' => metadata }
              end

              it 'is expected to respond with bad request' do
                expect(response.status).to eq(400)
              end

              it 'does not store metadata' do
                expect(stored_metadata_file).to be_nil
              end
            end
          end

          context "artifacts file is too large" do
            it "should fail to post too large artifact" do
              stub_application_setting(max_artifacts_size: 0)
              upload_artifacts(file_upload, headers_with_token)
              expect(response.status).to eq(413)
            end
          end

          context "artifacts post request does not contain file" do
            it "should fail to post artifacts without file" do
              post post_url, {}, headers_with_token
              expect(response.status).to eq(400)
            end
          end

          context 'GitLab Workhorse is not configured' do
            it "should fail to post artifacts without GitLab-Workhorse" do
              post post_url, { token: build.token }, {}
              expect(response.status).to eq(403)
            end
          end
        end

        context "artifacts are being stored outside of tmp path" do
          before do
            # by configuring this path we allow to pass file from @tmpdir only
            # but all temporary files are stored in system tmp directory
            @tmpdir = Dir.mktmpdir
            allow(ArtifactUploader).to receive(:artifacts_upload_path).and_return(@tmpdir)
          end

          after do
            FileUtils.remove_entry @tmpdir
          end

          it "should fail to post artifacts for outside of tmp path" do
            upload_artifacts(file_upload, headers_with_token)
            expect(response.status).to eq(400)
          end
        end

        def upload_artifacts(file, headers = {}, accelerated = true)
          if accelerated
            post post_url, {
              'file.path' => file.path,
              'file.name' => file.original_filename
            }, headers
          else
            post post_url, { file: file }, headers
          end
        end
      end

      describe 'DELETE /builds/:id/artifacts' do
        let(:build) { create(:ci_build, :artifacts) }
        before { delete delete_url, token: build.token }

        it 'should remove build artifacts' do
          expect(response.status).to eq(200)
          expect(build.artifacts_file.exists?).to be_falsy
          expect(build.artifacts_metadata.exists?).to be_falsy
        end
      end

      describe 'GET /builds/:id/artifacts' do
        before { get get_url, token: build.token }

        context 'build has artifacts' do
          let(:build) { create(:ci_build, :artifacts) }
          let(:download_headers) do
            { 'Content-Transfer-Encoding'=>'binary',
              'Content-Disposition'=>'attachment; filename=ci_build_artifacts.zip' }
          end

          it 'should download artifact' do
            expect(response.status).to eq(200)
            expect(response.headers).to include download_headers
          end
        end

        context 'build does not has artifacts' do
          it 'should respond with not found' do
            expect(response.status).to eq(404)
          end
        end
      end
    end
  end
end
