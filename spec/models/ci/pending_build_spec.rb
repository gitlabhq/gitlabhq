# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuild do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :created, pipeline: pipeline) }

  describe '.upsert_from_build!' do
    context 'another pending entry does not exist' do
      it 'creates a new pending entry' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
        expect(build.reload.queuing_entry).to be_present
      end
    end

    context 'when another queuing entry exists for given build' do
      before do
        described_class.create!(build: build, project: project)
      end

      it 'returns a build id as a result' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
      end
    end
  end
end
