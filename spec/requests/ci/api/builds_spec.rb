require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:runner) { FactoryGirl.create(:ci_runner, tag_list: ["mysql", "ruby"]) }
  let(:project) { FactoryGirl.create(:empty_project) }

  describe "Builds API for runners" do
    let(:pipeline) { create(:ci_pipeline_without_jobs, project: project, ref: 'master') }

    before do
      project.runners << runner
    end

    describe "POST /builds/register" do
      let!(:build) { create(:ci_build, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }

      it "starts a build" do
        register_builds info: { platform: :darwin }

        expect(response).to have_http_status(201)
        expect(json_response['sha']).to eq(build.sha)
        expect(runner.reload.platform).to eq("darwin")
        expect(json_response["options"]).to eq({ "image" => "ruby:2.1", "services" => ["postgres"] })
        expect(json_response["variables"]).to include(
          { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
          { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
          { "key" => "DB_NAME", "value" => "postgres", "public" => true }
        )
      end

      context 'when builds are finished' do
        before do
          build.success
        end

        it "returns 404 error if no builds for specific runner" do
          register_builds

          expect(response).to have_http_status(404)
        end
      end

      context 'for other project with builds' do
        before do
          build.success
          create(:ci_build, :pending)
        end

        it "returns 404 error if no builds for shared runner" do
          register_builds

          expect(response).to have_http_status(404)
        end
      end

      context 'for shared runner' do
        let(:shared_runner) { create(:ci_runner, token: "SharedRunner") }

        it "should return 404 error if no builds for shared runner" do
          register_builds shared_runner.token

          expect(response).to have_http_status(404)
        end
      end

      context 'for triggered build' do
        before do
          trigger = create(:ci_trigger, project: project)
          create(:ci_trigger_request_with_variables, pipeline: pipeline, builds: [build], trigger: trigger)
          project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")
        end

        it "returns variables for triggers" do
          register_builds info: { platform: :darwin }

          expect(response).to have_http_status(201)
          expect(json_response["variables"]).to include(
            { "key" => "CI_BUILD_NAME", "value" => "spinach", "public" => true },
            { "key" => "CI_BUILD_STAGE", "value" => "test", "public" => true },
            { "key" => "CI_BUILD_TRIGGERED", "value" => "true", "public" => true },
            { "key" => "DB_NAME", "value" => "postgres", "public" => true },
            { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false },
            { "key" => "TRIGGER_KEY_1", "value" => "TRIGGER_VALUE_1", "public" => false },
          )
        end
      end

      context 'with multiple builds' do
        before do
          build.success
        end

        let!(:test_build) { create(:ci_build, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

        it "returns dependent builds" do
          register_builds info: { platform: :darwin }

          expect(response).to have_http_status(201)
          expect(json_response["id"]).to eq(test_build.id)
          expect(json_response["depends_on_builds"].count).to eq(1)
          expect(json_response["depends_on_builds"][0]).to include('id' => build.id, 'name' => 'spinach')
        end
      end

      %w(name version revision platform architecture).each do |param|
        context "updates runner #{param}" do
          let(:value) { "#{param}_value" }

          subject { runner.read_attribute(param.to_sym) }

          it do
            register_builds info: { param => value }

            expect(response).to have_http_status(201)
            runner.reload
            is_expected.to eq(value)
          end
        end
      end

      context 'when build has no tags' do
        before do
          build.update(tags: [])
        end

        context 'when runner is allowed to pick untagged builds' do
          before { runner.update_column(:run_untagged, true) }

          it 'picks build' do
            register_builds

            expect(response).to have_http_status 201
          end
        end

        context 'when runner is not allowed to pick untagged builds' do
          before { runner.update_column(:run_untagged, false) }

          it 'does not pick build' do
            register_builds

            expect(response).to have_http_status 404
          end
        end
      end

      def register_builds(token = runner.token, **params)
        post ci_api("/builds/register"), params.merge(token: token)
      end
    end

    describe "PUT /builds/:id" do
      let(:build) { create(:ci_build, :pending, :trace, pipeline: pipeline, runner_id: runner.id) }

      before do
        build.run!
        put ci_api("/builds/#{build.id}"), token: runner.token
      end

      it "updates a running build" do
        expect(response).to have_http_status(200)
      end

      it 'does not override trace information when no trace is given' do
        expect(build.reload.trace).to eq 'BUILD TRACE'
      end

      context 'build has been erased' do
        let(:build) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it 'responds with forbidden' do
          expect(response.status).to eq 403
        end
      end
    end

    describe 'PATCH /builds/:id/trace.txt' do
      let(:build) { create(:ci_build, :pending, :trace, runner_id: runner.id) }
      let(:headers) { { Ci::API::Helpers::BUILD_TOKEN_HEADER => build.token, 'Content-Type' => 'text/plain' } }
      let(:headers_with_range) { headers.merge({ 'Content-Range' => '11-20' }) }

      before do
        build.run!
        patch ci_api("/builds/#{build.id}/trace.txt"), ' appended', headers_with_range
      end

      context 'when request is valid' do
        it { expect(response.status).to eq 202 }
        it { expect(build.reload.trace).to eq 'BUILD TRACE appended' }
        it { expect(response.header).to have_key 'Range' }
        it { expect(response.header).to have_key 'Build-Status' }
      end

      context 'when content-range start is too big' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '15-20' }) }

        it { expect(response.status).to eq 416 }
        it { expect(response.header).to have_key 'Range' }
        it { expect(response.header['Range']).to eq '0-11' }
      end

      context 'when content-range start is too small' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '8-20' }) }

        it { expect(response.status).to eq 416 }
        it { expect(response.header).to have_key 'Range' }
        it { expect(response.header['Range']).to eq '0-11' }
      end

      context 'when Content-Range header is missing' do
        let(:headers_with_range) { headers.merge({}) }

        it { expect(response.status).to eq 400 }
      end

      context 'when build has been errased' do
        let(:build) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it { expect(response.status).to eq 403 }
      end
    end

    context "Artifacts" do
      let(:file_upload) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/gif') }
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner_id: runner.id) }
      let(:authorize_url) { ci_api("/builds/#{build.id}/artifacts/authorize") }
      let(:post_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:delete_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:get_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:headers) { { "GitLab-Workhorse" => "1.0" } }
      let(:headers_with_token) { headers.merge(Ci::API::Helpers::BUILD_TOKEN_HEADER => build.token) }

      before { build.run! }

      describe "POST /builds/:id/artifacts/authorize" do
        context "authorizes posting artifact to running build" do
          it "using token as parameter" do
            post authorize_url, { token: build.token }, headers
            expect(response).to have_http_status(200)
            expect(json_response["TempPath"]).not_to be_nil
          end

          it "using token as header" do
            post authorize_url, {}, headers_with_token
            expect(response).to have_http_status(200)
            expect(json_response["TempPath"]).not_to be_nil
          end
        end

        context "fails to post too large artifact" do
          it "using token as parameter" do
            stub_application_setting(max_artifacts_size: 0)
            post authorize_url, { token: build.token, filesize: 100 }, headers
            expect(response).to have_http_status(413)
          end

          it "using token as header" do
            stub_application_setting(max_artifacts_size: 0)
            post authorize_url, { filesize: 100 }, headers_with_token
            expect(response).to have_http_status(413)
          end
        end

        context 'authorization token is invalid' do
          before { post authorize_url, { token: 'invalid', filesize: 100 } }

          it 'responds with forbidden' do
            expect(response).to have_http_status(403)
          end
        end
      end

      describe "POST /builds/:id/artifacts" do
        context "disable sanitizer" do
          before do
            # by configuring this path we allow to pass temp file from any path
            allow(ArtifactUploader).to receive(:artifacts_upload_path).and_return('/')
          end

          describe 'build has been erased' do
            let(:build) { create(:ci_build, erased_at: Time.now) }

            before do
              upload_artifacts(file_upload, headers_with_token)
            end

            it 'responds with forbidden' do
              expect(response.status).to eq 403
            end
          end

          describe 'uploading artifacts for a running build' do
            shared_examples 'successful artifacts upload' do
              it 'updates successfully' do
                response_filename =
                  json_response['artifacts_file']['filename']

                expect(response).to have_http_status(201)
                expect(response_filename).to eq(file_upload.original_filename)
              end
            end

            context 'uses regular file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, false)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'uses accelerated file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, true)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'updates artifact' do
              before do
                upload_artifacts(file_upload2, headers_with_token)
                upload_artifacts(file_upload, headers_with_token)
              end

              it_behaves_like 'successful artifacts upload'
            end
          end

          context 'posts artifacts file and metadata file' do
            let!(:artifacts) { file_upload }
            let!(:metadata) { file_upload2 }

            let(:stored_artifacts_file) { build.reload.artifacts_file.file }
            let(:stored_metadata_file) { build.reload.artifacts_metadata.file }
            let(:stored_artifacts_size) { build.reload.artifacts_size }

            before do
              post(post_url, post_data, headers_with_token)
            end

            context 'posts data accelerated by workhorse is correct' do
              let(:post_data) do
                { 'file.path' => artifacts.path,
                  'file.name' => artifacts.original_filename,
                  'metadata.path' => metadata.path,
                  'metadata.name' => metadata.original_filename }
              end

              it 'stores artifacts and artifacts metadata' do
                expect(response).to have_http_status(201)
                expect(stored_artifacts_file.original_filename).to eq(artifacts.original_filename)
                expect(stored_metadata_file.original_filename).to eq(metadata.original_filename)
                expect(stored_artifacts_size).to eq(71759)
              end
            end

            context 'no artifacts file in post data' do
              let(:post_data) do
                { 'metadata' => metadata }
              end

              it 'is expected to respond with bad request' do
                expect(response).to have_http_status(400)
              end

              it 'does not store metadata' do
                expect(stored_metadata_file).to be_nil
              end
            end
          end

          context 'with an expire date' do
            let!(:artifacts) { file_upload }

            let(:post_data) do
              { 'file.path' => artifacts.path,
                'file.name' => artifacts.original_filename,
                'expire_in' => expire_in }
            end

            before do
              post(post_url, post_data, headers_with_token)
            end

            context 'with an expire_in given' do
              let(:expire_in) { '7 days' }

              it 'updates when specified' do
                build.reload
                expect(response).to have_http_status(201)
                expect(json_response['artifacts_expire_at']).not_to be_empty
                expect(build.artifacts_expire_at).to be_within(5.minutes).of(Time.now + 7.days)
              end
            end

            context 'with no expire_in given' do
              let(:expire_in) { nil }

              it 'ignores if not specified' do
                build.reload
                expect(response).to have_http_status(201)
                expect(json_response['artifacts_expire_at']).to be_nil
                expect(build.artifacts_expire_at).to be_nil
              end
            end
          end

          context "artifacts file is too large" do
            it "fails to post too large artifact" do
              stub_application_setting(max_artifacts_size: 0)
              upload_artifacts(file_upload, headers_with_token)
              expect(response).to have_http_status(413)
            end
          end

          context "artifacts post request does not contain file" do
            it "fails to post artifacts without file" do
              post post_url, {}, headers_with_token
              expect(response).to have_http_status(400)
            end
          end

          context 'GitLab Workhorse is not configured' do
            it "fails to post artifacts without GitLab-Workhorse" do
              post post_url, { token: build.token }, {}
              expect(response).to have_http_status(403)
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

          it "fails to post artifacts for outside of tmp path" do
            upload_artifacts(file_upload, headers_with_token)
            expect(response).to have_http_status(400)
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

        before do
          delete delete_url, token: build.token
          build.reload
        end

        it 'removes build artifacts' do
          expect(response).to have_http_status(200)
          expect(build.artifacts_file.exists?).to be_falsy
          expect(build.artifacts_metadata.exists?).to be_falsy
          expect(build.artifacts_size).to be_nil
        end
      end

      describe 'GET /builds/:id/artifacts' do
        before { get get_url, token: build.token }

        context 'build has artifacts' do
          let(:build) { create(:ci_build, :artifacts) }
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
          end

          it 'downloads artifact' do
            expect(response).to have_http_status(200)
            expect(response.headers).to include download_headers
          end
        end

        context 'build does not has artifacts' do
          it 'responds with not found' do
            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end
end
