# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Rendered::Notebook::DiffFile, feature_category: :mlops do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:commit) { project.commit("5d6ed1503801ca9dc28e95eeb85a7cf863527aee") }
  let(:diffs) { commit.raw_diffs.to_a }
  let(:diff) { diffs.first }
  let(:source) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }
  let(:nb_file) { described_class.new(source) }

  describe '#old_blob and #new_blob' do
    context 'when file is changed' do
      it 'transforms the old blob' do
        expect(nb_file.old_blob.data).to include('%%')
      end

      it 'transforms the new blob' do
        expect(nb_file.new_blob.data).to include('%%')
      end
    end

    context 'when file is added' do
      let(:diff) { diffs[1] }

      it 'old_blob is empty' do
        expect(nb_file.old_blob).to be_nil
      end

      it 'new_blob is transformed' do
        expect(nb_file.new_blob.data).to include('%%')
      end
    end

    context 'when file is removed' do
      let(:diff) { diffs[2] }

      it 'old_blob is transformed' do
        expect(nb_file.old_blob.data).to include('%%')
      end

      it 'new_blob is empty' do
        expect(nb_file.new_blob).to be_nil
      end
    end
  end

  describe '#diff' do
    context 'for valid notebooks' do
      it 'returns the transformed diff' do
        expect(nb_file.diff.diff).to include('%%')
      end
    end

    context 'for invalid notebooks' do
      let(:commit) { project.commit("6d85bb693dddaee631ec0c2f697c52c62b93f6d3") }
      let(:diff) { diffs[1] }

      it 'returns nil' do
        expect(nb_file.diff).to be_nil
      end
    end

    context 'timeout' do
      it 'utilizes timeout for web' do
        expect(Timeout).to receive(:timeout).with(Gitlab::RenderTimeout::FOREGROUND).and_call_original

        nb_file.diff
      end

      it 'falls back to nil on timeout' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
        expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        expect(nb_file.diff).to be_nil
      end

      it 'utilizes longer timeout for sidekiq' do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        expect(Timeout).to receive(:timeout).with(described_class::RENDERED_TIMEOUT_BACKGROUND).and_call_original

        nb_file.diff
      end
    end
  end

  describe '#has_renderable?' do
    context 'notebook diff is empty' do
      let(:commit) { project.commit("a867a602d2220e5891b310c07d174fbe12122830") }

      it 'is false' do
        expect(nb_file.has_renderable?).to be_falsey
      end
    end

    context 'notebook is valid' do
      it 'is true' do
        expect(nb_file.has_renderable?).to be_truthy
      end
    end

    context 'when old blob file is truncated' do
      it 'is false' do
        allow(source.old_blob).to receive(:truncated?).and_return(true)

        expect(nb_file.has_renderable?).to be_falsey
      end
    end

    context 'when new blob file is truncated' do
      it 'is false' do
        allow(source.new_blob).to receive(:truncated?).and_return(true)

        expect(nb_file.has_renderable?).to be_falsey
      end
    end
  end

  describe '#highlighted_diff_lines?' do
    context 'when line transformed line is not part of the diff' do
      it 'line is not discussable' do
        expect(nb_file.highlighted_diff_lines[0].discussable?).to be_falsey
      end
    end

    context 'when line transformed line part of the diff' do
      it 'line is not discussable' do
        expect(nb_file.highlighted_diff_lines[12].discussable?).to be_truthy
      end
    end

    context 'assigns the correct position' do
      it 'computes the first line where the remove would appear' do
        expect(nb_file.highlighted_diff_lines[0].old_pos).to eq(3)
        expect(nb_file.highlighted_diff_lines[0].new_pos).to eq(3)

        expect(nb_file.highlighted_diff_lines[12].new_pos).to eq(15)
        expect(nb_file.highlighted_diff_lines[12].old_pos).to eq(18)
      end
    end

    context 'has image' do
      it 'replaces rich text with img to the embedded image' do
        expect(nb_file.highlighted_diff_lines[56].rich_text).to include('<img')
      end

      it 'adds image to src' do
        img = 'data:image/png;base64,some_image_here'
        allow(diff).to receive(:diff).and_return("@@ -1,76 +1,74 @@\n     ![](#{img})")

        expect(nb_file.highlighted_diff_lines[0].rich_text).to include("<img src=\"#{img}\"")
      end
    end

    context 'when embedded image has injected html' do
      let(:commit) { project.commit("4963fefc990451a8ad34289ce266b757456fc88c") }

      it 'prevents injected html to be rendered as html' do
        expect(nb_file.highlighted_diff_lines[43].rich_text).not_to include('<div>Hello')
      end

      it 'keeps the injected html as part of the string' do
        expect(nb_file.highlighted_diff_lines[43].rich_text).to end_with('/div&gt;">')
      end
    end
  end
end
