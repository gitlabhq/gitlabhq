# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::ManageEvidenceWorker do
  let(:project) { create(:project, :repository) }

  shared_examples_for 'does not create a new Evidence record' do
    specify :sidekiq_inline do
      aggregate_failures do
        expect(::Releases::CreateEvidenceService).not_to receive(:execute)
        expect { described_class.new.perform }.to change(Releases::Evidence, :count).by(0)
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

        expect { described_class.new.perform }.to change(Releases::Evidence, :count).by(1)
      end
    end

    context 'when evidence has already been created' do
      let(:release) { create(:release, project: project, released_at: 1.hour.since) }
      let!(:evidence) { create(:evidence, release: release )}

      it_behaves_like 'does not create a new Evidence record'
    end
  end

  context 'when `released_at` is outside the window' do
    let(:release) { create(:release, project: project, released_at: 300.minutes.since) }

    it_behaves_like 'does not create a new Evidence record'
  end
end
