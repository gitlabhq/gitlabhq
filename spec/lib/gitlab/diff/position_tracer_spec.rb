require 'spec_helper'

describe Gitlab::Diff::PositionTracer do
  include PositionTracerHelpers

  subject do
    described_class.new(
      project: project,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs
    )
  end

  describe '#trace' do
    let(:diff_refs) { double(complete?: true) }
    let(:project) { double }
    let(:old_diff_refs) { diff_refs }
    let(:new_diff_refs) { diff_refs }
    let(:position) { double(on_text?: on_text?, diff_refs: diff_refs) }
    let(:tracer) { double }

    context 'position is on text' do
      let(:on_text?) { true }

      it 'calls LineStrategy#trace' do
        expect(Gitlab::Diff::PositionTracer::LineStrategy)
          .to receive(:new)
          .with(subject)
          .and_return(tracer)
        expect(tracer).to receive(:trace).with(position)

        subject.trace(position)
      end
    end

    context 'position is not on text' do
      let(:on_text?) { false }

      it 'calls ImageStrategy#trace' do
        expect(Gitlab::Diff::PositionTracer::ImageStrategy)
          .to receive(:new)
          .with(subject)
          .and_return(tracer)
        expect(tracer).to receive(:trace).with(position)

        subject.trace(position)
      end
    end
  end

  describe 'diffs methods' do
    let(:project) { create(:project, :repository) }
    let(:current_user) { project.owner }

    let(:old_diff_refs) do
      diff_refs(
        project.commit(create_branch('new-branch', 'master')[:branch].name),
        create_file('new-branch', 'file.md', 'content')
      )
    end

    let(:new_diff_refs) do
      diff_refs(
        create_file('new-branch', 'file.md', 'content'),
        update_file('new-branch', 'file.md', 'updatedcontent')
      )
    end

    describe '#ac_diffs' do
      it 'returns the diffs between the base of old and new diff' do
        diff_refs = subject.ac_diffs.diff_refs

        expect(diff_refs.base_sha).to eq(old_diff_refs.base_sha)
        expect(diff_refs.start_sha).to eq(old_diff_refs.base_sha)
        expect(diff_refs.head_sha).to eq(new_diff_refs.base_sha)
      end
    end

    describe '#bd_diffs' do
      it 'returns the diffs between the HEAD of old and new diff' do
        diff_refs = subject.bd_diffs.diff_refs

        expect(diff_refs.base_sha).to eq(old_diff_refs.head_sha)
        expect(diff_refs.start_sha).to eq(old_diff_refs.head_sha)
        expect(diff_refs.head_sha).to eq(new_diff_refs.head_sha)
      end
    end

    describe '#cd_diffs' do
      it 'returns the diffs in the new diff' do
        diff_refs = subject.cd_diffs.diff_refs

        expect(diff_refs.base_sha).to eq(new_diff_refs.base_sha)
        expect(diff_refs.start_sha).to eq(new_diff_refs.base_sha)
        expect(diff_refs.head_sha).to eq(new_diff_refs.head_sha)
      end
    end
  end
end
