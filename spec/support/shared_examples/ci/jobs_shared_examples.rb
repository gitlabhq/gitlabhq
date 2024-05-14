# frozen_string_literal: true

RSpec.shared_examples 'a job with artifacts and trace' do |result_is_array: true|
  context 'with artifacts and trace' do
    let!(:second_job) { create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline) }

    it 'returns artifacts and trace data', :skip_before_request do
      get api(api_endpoint, api_user)
      json_job = json_response.is_a?(Array) ? json_response.find { |job| job['id'] == second_job.id } : json_response

      expect(json_job['artifacts_file']).not_to be_nil
      expect(json_job['artifacts_file']).not_to be_empty
      expect(json_job['artifacts_file']['filename']).to eq(second_job.artifacts_file.filename)
      expect(json_job['artifacts_file']['size']).to eq(second_job.artifacts_file.size)
      expect(json_job['artifacts']).not_to be_nil
      expect(json_job['artifacts']).to be_an Array
      expect(json_job['artifacts'].size).to eq(second_job.job_artifacts.length)
      json_job['artifacts'].each do |artifact|
        expect(artifact).not_to be_nil
        file_type = Ci::JobArtifact.file_types[artifact['file_type']]
        expect(artifact['size']).to eq(second_job.job_artifacts.find_by(file_type: file_type).size)
        expect(artifact['filename']).to eq(second_job.job_artifacts.find_by(file_type: file_type).filename)
        expect(artifact['file_format']).to eq(second_job.job_artifacts.find_by(file_type: file_type).file_format)
      end
    end
  end
end

RSpec.shared_context 'when canceling support' do
  before do
    job.metadata.set_cancel_gracefully
    job.save!
  end
end
