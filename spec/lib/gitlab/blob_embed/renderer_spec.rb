# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BlobEmbed::Renderer, feature_category: :markdown do
  let_it_be(:project) { create(:project, :repository) }

  let(:sha) { project.commit.sha }
  let(:path) { 'files/ruby/popen.rb' }
  let(:from) { 3 }
  let(:to) { 6 }
  let(:cross_project) { false }
  let(:line_count) { project.repository.blob_at(sha, path).data.each_line.count }

  subject(:renderer) { fresh_renderer }

  # A renderer memoises its blob, so caching behaviour has to be observed across
  # separate instances.
  def fresh_renderer
    described_class.new(
      project: project, sha: sha, path: path, from: from, to: to, cross_project: cross_project
    )
  end

  def rendered
    Nokogiri::HTML5.fragment(renderer.render.to_s)
  end

  describe '#render' do
    it 'renders an embed for a valid range' do
      expect(renderer.render).to be_present
    end

    it 'titles the embed with the blob path alone' do
      expect(rendered.at_css('.blob-embed-title').text).to eq(path)
    end

    context 'when the embed points outside the surrounding document\'s project' do
      let(:cross_project) { true }

      it 'qualifies the title with the project full path' do
        expect(rendered.at_css('.blob-embed-title').text).to eq("#{project.full_path}/#{path}")
      end
    end

    context 'when the window overhangs the end of the file' do
      let(:from) { line_count - 1 }
      let(:to) { line_count + 20 }

      it 'numbers only the lines the file has' do
        gutter = rendered.css('.line-numbers .diff-line-num')

        expect(gutter.size).to eq(2)
        expect(gutter.last.text).to eq(line_count.to_s)
      end
    end

    context 'when the window starts past the end of the file' do
      let(:from) { line_count + 5 }
      let(:to) { line_count + 6 }

      it { expect(renderer.render).to be_nil }
    end

    context 'when ActionView annotates rendered views with filenames' do
      before do
        allow(ActionView::Base).to receive(:annotate_rendered_view_with_filenames).and_return(true)
      end

      it 'leaves no comment nodes in the output' do
        expect(rendered.xpath('.//comment()')).to be_empty
      end
    end

    context 'when the range is invalid' do
      [[0, 6], [6, 3], [1, described_class::MAX_LINES + 2]].each do |bad_from, bad_to|
        it "returns nil for lines #{bad_from}-#{bad_to}" do
          renderer = described_class.new(project: project, sha: sha, path: path, from: bad_from, to: bad_to)

          expect(renderer.render).to be_nil
        end
      end
    end

    context 'when the window ends past the highlight ceiling' do
      let(:from) { described_class::MAX_TO_LINES + 1 }
      let(:to) { described_class::MAX_TO_LINES + 2 }

      it 'rejects it without reading the blob' do
        expect(project.repository).not_to receive(:blob_at)

        expect(renderer.render).to be_nil
      end
    end

    context 'when the blob is binary' do
      let(:path) { 'files/images/logo-black.png' }

      it { expect(renderer.render).to be_nil }
    end

    context 'when the blob does not exist' do
      let(:path) { 'does/not/exist.rb' }

      it { expect(renderer.render).to be_nil }
    end

    context 'when the caller supplies the blob' do
      subject(:renderer) do
        described_class.new(project: project, sha: sha, path: path, from: from, to: to, blob: blob)
      end

      let!(:blob) { project.repository.blob_at(sha, path) }

      it 'uses it instead of reading the blob itself' do
        expect(project.repository).not_to receive(:blob_at)

        expect(renderer.render).to be_present
      end

      context 'when it is stored externally' do
        before do
          allow(blob).to receive(:stored_externally?).and_return(true)
        end

        it { expect(renderer.render).to be_nil }
      end

      context 'when it is larger than the display limit' do
        before do
          allow(blob).to receive(:size).and_return(Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE + 1)
        end

        it 'does not read the whole blob into memory' do
          expect(blob).not_to receive(:load_all_data!)

          expect(renderer.render).to be_nil
        end
      end
    end

    context 'when the repository read fails' do
      before do
        allow(project.repository).to receive(:blob_at).and_raise(GRPC::Unavailable)
      end

      it 'tracks the exception and renders nothing' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(GRPC::Unavailable), project_id: project.id)

        expect(renderer.render).to be_nil
      end

      it 'tries again on the next render rather than caching the failure' do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect(project.repository).to receive(:blob_at).twice.and_raise(GRPC::Unavailable)

        2.times { expect(fresh_renderer.render).to be_nil }
      end
    end

    it 'fetches and highlights each unique embed only once' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      expect(project.repository).to receive(:blob_at).once.and_call_original

      2.times { fresh_renderer.render }
    end

    context 'when the blob cannot be embedded' do
      let(:path) { 'files/images/logo-black.png' }

      # The commit is immutable, so a blob that cannot be embedded *never* can be.
      it 'caches the nil answer rather than re-reading the blob' do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

        expect(project.repository).to receive(:blob_at).once.and_call_original

        2.times { expect(fresh_renderer.render).to be_nil }
      end
    end
  end
end
