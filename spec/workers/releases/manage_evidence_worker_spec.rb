# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::ManageEvidenceWorker, feature_category: :release_evidence do
  let(:project) { create(:project, :repository) }

  shared_examples_for 'does not create a new Evidence record' do
    specify :sidekiq_inline do
      aggregate_failures do
        expect(::Releases::CreateEvidenceService).not_to receive(:execute)
        expect { described_class.new.perform }.to change { Releases::Evidence.count }.by(0)
      end
    end
  end

  context 'when `released_at` in inside the window' do
    context 'when Evidence has not been created' do
      let(:release) { create(:release, project: project, released_at: 1.hour.since) }

      it 'creates a new Evidence record', :sidekiq_inline do
        expect_next_instance_of(::Releases::CreateEvidenceService, release, { pipeline: nil }) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { described_class.new.perform }.to change { Releases::Evidence.count }.by(1)
      end
    end

    context 'when pipeline finder times out' do
      let!(:release_without_evidence) { create(:release, project: project, released_at: 1.hour.since) }
      let!(:release_with_evidence) { create(:release, project: project, released_at: 1.hour.since) }
      let!(:evidence) { create(:evidence, release: release_with_evidence) }
      let(:finder) { instance_double(Releases::EvidencePipelineFinder) }

      it 'continues processing other releases', :sidekiq_inline do
        allow(Releases::EvidencePipelineFinder).to receive(:new)
        .with(release_without_evidence.project, tag: release_without_evidence.tag)
        .and_return(finder)
        allow(finder).to receive(:execute).and_raise(ActiveRecord::StatementTimeout)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(ActiveRecord::StatementTimeout),
          release_id: release_without_evidence.id,
          project_id: project.id
        )

        expect { described_class.new.perform }.to change { Releases::Evidence.count }.by(0)
      end
    end

    context 'when pipeline finder raises error' do
      let(:finder) { instance_double(Releases::EvidencePipelineFinder) }
      let!(:release) { create(:release, project: project, released_at: 1.hour.since) }

      it 'tracks error and continues' do
        allow(Releases::EvidencePipelineFinder).to receive(:new)
        .with(release.project, tag: release.tag)
        .and_return(finder)
        allow(finder).to receive(:execute).and_raise(StandardError)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(StandardError),
          release_id: release.id,
          project_id: project.id
        )

        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context 'when evidence has already been created' do
      let(:release) { create(:release, project: project, released_at: 1.hour.since) }
      let!(:evidence) { create(:evidence, release: release) }

      it_behaves_like 'does not create a new Evidence record'
    end
  end

  context 'when `released_at` is outside the window' do
    let(:release) { create(:release, project: project, released_at: 300.minutes.since) }

    it_behaves_like 'does not create a new Evidence record'
  end
end
