# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PersistentRef do
  it 'cleans up persistent refs after pipeline finished' do
    pipeline = create(:ci_pipeline, :running)

    expect(pipeline.persistent_ref).to receive(:delete).once

    pipeline.succeed!
  end

  describe '#exist?' do
    subject { pipeline.persistent_ref.exist? }

    let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
    let(:project) { create(:project, :repository) }
    let(:sha) { project.repository.commit.sha }

    context 'when a persistent ref does not exist' do
      it { is_expected.to eq(false) }
    end

    context 'when a persistent ref exists' do
      before do
        pipeline.persistent_ref.create # rubocop: disable Rails/SaveBang
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#create' do
    subject { pipeline.persistent_ref.create } # rubocop: disable Rails/SaveBang

    let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
    let(:project) { create(:project, :repository) }
    let(:sha) { project.repository.commit.sha }

    context 'when a persistent ref does not exist' do
      it 'creates a persistent ref' do
        subject

        expect(pipeline.persistent_ref).to be_exist
      end

      context 'when sha does not exist in the repository' do
        let(:sha) { 'not-exist' }

        it 'fails to create a persistent ref' do
          subject

          expect(pipeline.persistent_ref).not_to be_exist
        end
      end
    end

    context 'when a persistent ref already exists' do
      before do
        pipeline.persistent_ref.create # rubocop: disable Rails/SaveBang
      end

      it 'overwrites a persistent ref' do
        expect(project.repository).to receive(:create_ref).and_call_original

        subject
      end
    end
  end

  describe '#delete' do
    subject { pipeline.persistent_ref.delete }

    let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
    let(:project) { create(:project, :repository) }
    let(:sha) { project.repository.commit.sha }

    context 'when a persistent ref exists' do
      before do
        pipeline.persistent_ref.create # rubocop: disable Rails/SaveBang
      end

      it 'deletes the ref' do
        expect { subject }.to change { pipeline.persistent_ref.exist? }
                          .from(true).to(false)
      end
    end

    context 'when a persistent ref does not exist' do
      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
