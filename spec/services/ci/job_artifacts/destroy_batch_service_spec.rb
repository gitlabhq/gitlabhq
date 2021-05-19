# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyBatchService do
  let(:artifacts) { Ci::JobArtifact.all }
  let(:service) { described_class.new(artifacts, pick_up_at: Time.current) }

  describe '.execute' do
    subject(:execute) { service.execute }

    let_it_be(:artifact, refind: true) do
      create(:ci_job_artifact)
    end

    context 'when the artifact has a file attached to it' do
      before do
        artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
        artifact.save!
      end

      it 'creates a deleted object' do
        expect { subject }.to change { Ci::DeletedObject.count }.by(1)
      end

      it 'does not remove the files' do
        expect { execute }.not_to change { artifact.file.exists? }
      end

      it 'reports metrics for destroyed artifacts' do
        expect_next_instance_of(Gitlab::Ci::Artifacts::Metrics) do |metrics|
          expect(metrics).to receive(:increment_destroyed_artifacts).with(1).and_call_original
        end

        execute
      end

      context 'ProjectStatistics' do
        it 'resets project statistics' do
          expect(ProjectStatistics).to receive(:increment_statistic).once
            .with(artifact.project, :build_artifacts_size, -artifact.file.size)
            .and_call_original

          execute
        end

        context 'with update_stats: false' do
          it 'does not update project statistics' do
            expect(ProjectStatistics).not_to receive(:increment_statistic)

            service.execute(update_stats: false)
          end

          it 'returns size statistics' do
            expect(service.execute(update_stats: false)).to match(
              a_hash_including(statistics_updates: { artifact.project => -artifact.file.size }))
          end
        end
      end
    end

    context 'when failed to destroy artifact' do
      context 'when the import fails' do
        before do
          expect(Ci::DeletedObject)
            .to receive(:bulk_import)
            .once
            .and_raise(ActiveRecord::RecordNotDestroyed)
        end

        it 'raises an exception and stop destroying' do
          expect { execute }.to raise_error(ActiveRecord::RecordNotDestroyed)
                            .and not_change { Ci::JobArtifact.count }.from(1)
        end
      end
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { execute }.not_to raise_error
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(destroyed_artifacts_count: 0, statistics_updates: {}, status: :success)
      end
    end
  end
end
