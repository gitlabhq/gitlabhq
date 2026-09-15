# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Jobs::GetArtifactFileService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: [user]) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  # The :artifacts trait attaches spec/fixtures/ci_build_artifacts.zip, whose entries
  # (ci_artifacts.txt, rails_sample.jpg, ...) these examples read.
  let_it_be(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, name: 'rspec') }

  let(:current_user) { user }
  let(:text_file) { 'ci_artifacts.txt' }
  let(:text_file_content) { "CI build artifacts fixture\n" }
  let(:text_file_size) { text_file_content.bytesize }

  def execute(arguments)
    service = described_class.new(name: 'get_artifact_file', version: '0.1.0')
    service.set_cred(current_user: current_user)
    service.execute(params: { name: 'get_artifact_file', arguments: arguments })
  end

  describe 'class configuration' do
    it 'registers version 0.1.0 as read-only' do
      expect(described_class.available_versions).to include('0.1.0')
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the job, for example ' \
              'https://gitlab.com/gitlab-org/gitlab/-/jobs/123. ' \
              'Provide this, or project_id and job_id.'
          },
          project_id: {
            type: 'string',
            description: 'ID or full path of the project. Required if url is not provided.'
          },
          job_id: {
            type: 'integer',
            description: 'ID of the job. Required if url is not provided.'
          },
          artifact_path: {
            type: 'string',
            description: 'Path of the file inside the artifacts archive, for example coverage/index.html.'
          },
          byte_offset: {
            type: 'integer',
            minimum: 0,
            maximum: 100.megabytes,
            description: 'Byte offset to start reading the file from.'
          },
          byte_limit: {
            type: 'integer',
            minimum: 1,
            maximum: 1.megabyte,
            description: 'Maximum number of bytes to return.'
          }
        },
        required: %w[artifact_path]
      })
    end
  end

  describe '#execute' do
    it 'reads a text file out of the artifacts archive', :aggregate_failures do
      result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to eq({
        path: text_file,
        job_id: job.id,
        metadata: {
          total_bytes: text_file_size,
          returned: { start: 0, end: text_file_size },
          truncated: false
        },
        content: text_file_content
      })
    end

    it 'reads a file nested in a directory' do
      result = execute({
        project_id: project.full_path, job_id: job.id,
        artifact_path: 'other_artifacts_0.1.2/doc_sample.txt'
      })

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent][:metadata][:total_bytes]).to eq(1314)
    end

    context 'with a byte window' do
      it 'truncates and points at the next byte_offset', :aggregate_failures do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file, byte_limit: 5 })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:content].bytesize).to eq(5)
        expect(result[:structuredContent][:metadata]).to eq({
          total_bytes: text_file_size,
          returned: { start: 0, end: 5 },
          truncated: true
        })
        expect(result[:structuredContent][:system_instruction]).to eq(
          "Artifact file truncated. Remaining: #{text_file_size - 5} bytes. " \
            'Call again with {"byte_offset": 5}.'
        )
      end

      it 'continues from byte_offset, and the windows join up to the whole file', :aggregate_failures do
        first_window = execute({
          project_id: project.full_path, job_id: job.id, artifact_path: text_file, byte_limit: 5
        })
        second_window = execute({
          project_id: project.full_path, job_id: job.id, artifact_path: text_file, byte_offset: 5
        })

        expect(second_window[:isError]).to be(false)
        expect(second_window[:structuredContent][:metadata][:returned]).to eq(
          { start: 5, end: text_file_size }
        )

        whole = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })
        expect(first_window[:structuredContent][:content] + second_window[:structuredContent][:content])
          .to eq(whole[:structuredContent][:content])
      end

      it 'reports an empty window without inflating the entry when byte_offset is past the end of the file' do
        expect(Zip::Inflater).not_to receive(:new)

        result = execute({
          project_id: project.full_path, job_id: job.id, artifact_path: text_file, byte_offset: 100
        })

        expect(result[:structuredContent][:metadata]).to eq({
          total_bytes: text_file_size,
          returned: { start: text_file_size, end: text_file_size },
          truncated: false
        })
      end

      describe 'end-of-stream probe' do
        let(:service) { described_class.new(name: 'get_artifact_file', version: '0.1.0') }

        it 'reports no more data when the stream ends before the declared size' do
          content, truncated = service.send(:window_from, StringIO.new(''), 'abc', 0, 10)

          expect(content).to eq('abc')
          expect(truncated).to be(false)
        end

        it 'reports more data when the stream continues past the window' do
          content, truncated = service.send(:window_from, StringIO.new('def'), 'abc', 0, 3)

          expect(content).to eq('abc')
          expect(truncated).to be(true)
        end
      end

      context 'when the archive lies about the entry size' do
        before do
          # rubocop:disable RSpec/AnyInstanceOf -- entries are built inside rubyzip while parsing the archive
          allow_any_instance_of(Zip::Entry).to receive(:size).and_return(1000)
          # rubocop:enable RSpec/AnyInstanceOf
        end

        it 'trusts the metadata size over the declared one', :aggregate_failures do
          result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent][:metadata]).to eq({
            total_bytes: text_file_size,
            returned: { start: 0, end: text_file_size },
            truncated: false
          })
        end
      end

      it 'rejects a byte_limit above the maximum' do
        result = execute({
          project_id: project.full_path, job_id: job.id, artifact_path: text_file, byte_limit: 1.megabyte + 1
        })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('byte_limit is invalid')
      end
    end

    context 'when the file is binary' do
      it 'returns an error carrying the file name, job ID, file type, and a viewing URL', :aggregate_failures do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: 'rails_sample.jpg' })

        expect(result[:isError]).to be(true)
        message = result[:content].first[:text]
        expect(message).to include("Artifact file 'rails_sample.jpg' in job #{job.id} is binary (image/jpeg)")
        expect(message).to include('Size: 35255 bytes')
        expect(message).to include(
          Gitlab::Routing.url_helpers.raw_project_job_artifacts_url(project, job, path: 'rails_sample.jpg')
        )
      end
    end

    context 'when the file does not exist in the archive' do
      it 'returns an error listing files that do exist', :aggregate_failures do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: 'nope.txt' })

        expect(result[:isError]).to be(true)
        message = result[:content].first[:text]
        expect(message).to include("Artifact file 'nope.txt' not found in the artifacts archive of job #{job.id}")
        expect(message).to include(text_file)
      end
    end

    context 'when the archive has no metadata' do
      let_it_be(:no_metadata_job) { create(:ci_build, :success, pipeline: pipeline) }

      before_all do
        create(:ci_job_artifact, :archive, job: no_metadata_job)
      end

      it 'still reads the file from the archive itself' do
        result = execute({ project_id: project.full_path, job_id: no_metadata_job.id, artifact_path: text_file })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:metadata][:total_bytes]).to eq(text_file_size)
      end

      it 'reports a missing file without a listing' do
        result = execute({ project_id: project.full_path, job_id: no_metadata_job.id, artifact_path: 'nope.txt' })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).not_to include('Files in the archive include')
      end

      it 'refuses a path that is a directory, not a file' do
        result = execute({
          project_id: project.full_path, job_id: no_metadata_job.id, artifact_path: 'other_artifacts_0.1.2'
        })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('is not a regular file')
      end
    end

    context 'when the archive lives in object storage' do
      let_it_be(:remote_job) { create(:ci_build, :success, pipeline: pipeline) }

      before do
        stub_artifacts_object_storage
        create(:ci_job_artifact, :archive, :remote_store, job: remote_job)
        stub_request(:get, %r{\Ahttps://artifacts\.s3\.amazonaws\.com/})
          .to_return(status: 200, body: File.binread(Rails.root.join('spec/fixtures/ci_build_artifacts.zip')))
      end

      it 'downloads and reads the file' do
        result = execute({ project_id: project.full_path, job_id: remote_job.id, artifact_path: text_file })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:content]).to eq(text_file_content)
      end
    end

    context 'when the job has no artifacts archive' do
      let_it_be(:bare_job) { create(:ci_build, :success, pipeline: pipeline) }

      it 'says so' do
        result = execute({ project_id: project.full_path, job_id: bare_job.id, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Job #{bare_job.id} has no artifacts archive.")
      end
    end

    context 'when the artifacts have expired' do
      let_it_be(:unlocked_pipeline) { create(:ci_pipeline, :unlocked, project: project) }
      let_it_be(:expired_job) do
        create(:ci_build, :success, :artifacts, pipeline: unlocked_pipeline, artifacts_expire_at: 1.day.ago)
      end

      it 'names the expiry as the reason' do
        result = execute({ project_id: project.full_path, job_id: expired_job.id, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('The artifacts have expired.')
      end
    end

    context 'when the artifacts are past expiry but kept by a locked pipeline' do
      let_it_be(:locked_pipeline) { create(:ci_pipeline, :artifacts_locked, project: project) }
      let_it_be(:locked_job) do
        create(:ci_build, :success, :artifacts, pipeline: locked_pipeline, artifacts_expire_at: 1.day.ago)
      end

      it 'still reads the file, matching the REST download endpoints' do
        result = execute({ project_id: project.full_path, job_id: locked_job.id, artifact_path: text_file })

        expect(result[:isError]).to be_falsey
        expect(result[:structuredContent][:content]).to eq(text_file_content)
      end
    end

    context 'when the archive is larger than the download cap' do
      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:artifacts_size).and_return(described_class::MAX_ARCHIVE_BYTES + 1)
        end
      end

      it 'refuses with a pointer to the download URL', :aggregate_failures do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('exceeds')
        expect(result[:content].first[:text]).to include(
          Gitlab::Routing.url_helpers.download_project_job_artifacts_url(project, job)
        )
      end
    end

    context 'when the archive has more entries than the cap' do
      before do
        stub_const("#{described_class}::MAX_ARCHIVE_ENTRIES", 3)
      end

      it 'refuses with a pointer to the download URL, without opening the archive', :aggregate_failures do
        expect(Zip::File).not_to receive(:open)

        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('has more than 3 entries')
        expect(result[:content].first[:text]).to include(
          Gitlab::Routing.url_helpers.download_project_job_artifacts_url(project, job)
        )
      end
    end

    describe 'job identification' do
      it 'accepts a job URL' do
        result = execute({
          url: Gitlab::Routing.url_helpers.project_job_url(project, job), artifact_path: text_file
        })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:job_id]).to eq(job.id)
      end

      it 'accepts an artifact file URL whose embedded path matches artifact_path' do
        url = "#{Gitlab::Routing.url_helpers.project_job_url(project, job)}/artifacts/file/#{text_file}"
        result = execute({ url: url, artifact_path: text_file })

        expect(result[:isError]).to be(false)
      end

      it 'rejects an artifact file URL whose embedded path contradicts artifact_path' do
        url = "#{Gitlab::Routing.url_helpers.project_job_url(project, job)}/artifacts/file/other.txt"
        result = execute({ url: url, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Artifact path mismatch')
      end

      it 'rejects a URL that is not a job URL' do
        result = execute({ url: "#{Gitlab.config.gitlab.url}/#{project.full_path}", artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Invalid job URL')
      end

      it 'rejects a non-http URL instead of crashing' do
        result = execute({ url: 'mailto:a@b.example', artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Invalid URL format')
      end

      context 'when the instance is served under a relative URL root' do
        before do
          stub_config_setting(relative_url_root: '/gitlab')
          described_class.clear_memoization(:relative_url_root_regex)
        end

        after do
          described_class.clear_memoization(:relative_url_root_regex)
        end

        it 'strips the relative URL root from a job URL' do
          url = "#{Gitlab.config.gitlab.url}/gitlab/#{project.full_path}/-/jobs/#{job.id}"

          result = execute({ url: url, artifact_path: text_file })

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent][:job_id]).to eq(job.id)
        end
      end

      it 'does not turn a literal plus in the path into a space' do
        url = "#{Gitlab::Routing.url_helpers.project_job_url(project, job)}/artifacts/file/nope+file.txt"

        result = execute({ url: url, artifact_path: 'nope+file.txt' })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('not found in the artifacts archive')
        expect(result[:content].first[:text]).not_to include('mismatch')
      end

      it 'percent-decodes the embedded artifact path before comparing' do
        url = "#{Gitlab::Routing.url_helpers.project_job_url(project, job)}/artifacts/file/" \
          'other_artifacts_0.1.2/%64oc_sample.txt'

        result = execute({ url: url, artifact_path: 'other_artifacts_0.1.2/doc_sample.txt' })

        expect(result[:isError]).to be(false)
      end

      it 'rejects url combined with project_id or job_id', :aggregate_failures do
        result = execute({
          url: Gitlab::Routing.url_helpers.project_job_url(project, job),
          project_id: project.full_path,
          artifact_path: text_file
        })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Provide either url, or project_id and job_id, not both')
      end

      it 'rejects a call with neither url nor both ids' do
        result = execute({ project_id: project.full_path, artifact_path: text_file })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Provide either url, or project_id and job_id')
      end
    end

    describe 'artifact_path validation' do
      it 'rejects a directory path' do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: 'other_artifacts_0.1.2/' })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('must be a file path, not a directory')
      end

      it 'rejects a path traversal sequence' do
        result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: '../secrets.txt' })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('path traversal')
      end
    end

    describe 'authorization' do
      context 'when the job does not exist' do
        it 'returns an error that does not distinguish missing from inaccessible' do
          result = execute({ project_id: project.full_path, job_id: non_existing_record_id,
                             artifact_path: text_file })

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('Job not found or inaccessible')
        end
      end

      context 'when the user cannot read the project' do
        let_it_be(:private_project) { create(:project, :private) }
        let_it_be(:private_job) do
          create(:ci_build, :artifacts, pipeline: create(:ci_pipeline, project: private_project))
        end

        let(:current_user) { create(:user) }

        it 'returns the same error as a project that does not exist' do
          result = execute({ project_id: private_project.full_path, job_id: private_job.id,
                             artifact_path: text_file })

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include(
            "Project '#{private_project.full_path}' not found or inaccessible"
          )
        end
      end

      context 'when the user can read the job but not its artifacts' do
        let_it_be(:guarded_project) { create(:project, :public) }
        let_it_be(:guarded_job) do
          create(:ci_build, :success, :private_artifacts, pipeline: create(:ci_pipeline, project: guarded_project))
        end

        let(:current_user) { create(:user) }

        it 'hides whether the job exists' do
          result = execute({ project_id: guarded_project.full_path, job_id: guarded_job.id,
                             artifact_path: text_file })

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('Job not found or inaccessible')
        end
      end

      context 'when current_user is not set' do
        let(:current_user) { nil }

        it 'returns an error' do
          result = execute({ project_id: project.full_path, job_id: job.id, artifact_path: text_file })

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('current_user is not set')
        end
      end
    end
  end
end
