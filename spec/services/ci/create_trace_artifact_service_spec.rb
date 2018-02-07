require 'spec_helper'

describe Ci::CreateTraceArtifactService do
  describe '#execute' do
    subject { described_class.new(nil, nil).execute(job) }

    let(:job) { create(:ci_build) }

    context 'when the job does not have trace artifact' do
      context 'when the job has a trace file' do
        before do
          allow_any_instance_of(Gitlab::Ci::Trace)
            .to receive(:default_path) { expand_fixture_path('trace/sample_trace') }

          allow_any_instance_of(JobArtifactUploader).to receive(:move_to_cache) { false }
          allow_any_instance_of(JobArtifactUploader).to receive(:move_to_store) { false }
        end

        it 'creates trace artifact' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(1)

          expect(job.job_artifacts_trace.read_attribute(:file)).to eq('sample_trace')
        end

        context 'when the job has already had trace artifact' do
          before do
            create(:ci_job_artifact, :trace, job: job)
          end

          it 'does not create trace artifact' do
            expect { subject }.not_to change { Ci::JobArtifact.count }
          end
        end
      end

      context 'when the job does not have a trace file' do
        it 'does not create trace artifact' do
          expect { subject }.not_to change { Ci::JobArtifact.count }
        end
      end
    end
  end
end
