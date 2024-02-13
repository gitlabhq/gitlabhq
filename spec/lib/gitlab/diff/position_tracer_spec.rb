# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::PositionTracer do
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
    let(:on_file?) { false }
    let(:on_text?) { false }
    let(:tracer) { double }
    let(:position) do
      double(on_text?: on_text?, on_image?: false, on_file?: on_file?, diff_refs: diff_refs,
        ignore_whitespace_change: false)
    end

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

    context 'position on file' do
      let(:on_file?) { true }

      it 'calls ImageStrategy#trace' do
        expect(Gitlab::Diff::PositionTracer::FileStrategy)
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
    let(:current_user) { project.first_owner }

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

    describe 'when requesting diffs' do
      shared_examples 'it does not call diff stats' do
        it 'does not call diff stats' do
          expect_next_instance_of(Compare) do |instance|
            expect(instance).to receive(:diffs).with(hash_including(include_stats: false)).and_call_original
          end

          diff_files
        end
      end

      context 'ac diffs' do
        let(:diff_files) { subject.ac_diffs.diff_files }

        it_behaves_like 'it does not call diff stats'
      end

      context 'bd diffs' do
        let(:diff_files) { subject.bd_diffs.diff_files }

        it_behaves_like 'it does not call diff stats'
      end

      context 'cd diffs' do
        let(:diff_files) { subject.cd_diffs.diff_files }

        it_behaves_like 'it does not call diff stats'
      end
    end
  end
end
