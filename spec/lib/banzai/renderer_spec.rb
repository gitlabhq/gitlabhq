# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Renderer do
  let(:renderer) { described_class }

  def fake_object(fresh:)
    object = double('object')

    allow(object).to receive(:respond_to?).with(:cached_markdown_fields).and_return(true)
    allow(object).to receive(:cached_html_up_to_date?).with(:field).and_return(fresh)
    allow(object).to receive(:cached_html_for).with(:field).and_return('field_html')

    object
  end

  def fake_cacheless_object
    object = double('cacheless object')

    allow(object).to receive(:respond_to?).with(:cached_markdown_fields).and_return(false)

    object
  end

  describe '#cache_collection_render' do
    let(:merge_request) { fake_object(fresh: true) }
    let(:context) { { cache_key: [merge_request, 'field'], rendered: merge_request.field_html } }

    context 'when an item has a rendered field' do
      before do
        allow(merge_request).to receive(:field).and_return('This is the field')
        allow(merge_request).to receive(:field_html).and_return('This is the field')
      end

      it 'does not touch redis if the field is in the cache' do
        expect(Rails).not_to receive(:cache)

        described_class.cache_collection_render([{ text: merge_request.field, context: context }])
      end
    end
  end

  describe '#render_field' do
    context 'without cache' do
      let(:commit) { fake_cacheless_object }

      it 'returns cacheless render field' do
        expect(renderer).to receive(:cacheless_render_field).with(commit, :field, {})

        renderer.render_field(commit, :field)
      end
    end

    context 'with cache' do
      subject { renderer.render_field(object, :field) }

      context 'with a stale cache' do
        let(:object) { fake_object(fresh: false) }

        it 'caches and returns the result' do
          expect(object).to receive(:refresh_markdown_cache!)

          is_expected.to eq('field_html')
        end

        it "skips database caching on a GitLab read-only instance" do
          allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
          expect(object).to receive(:refresh_markdown_cache!)

          is_expected.to eq('field_html')
        end
      end

      context 'with an up-to-date cache' do
        let(:object) { fake_object(fresh: true) }

        it 'uses the cache' do
          expect(object).to receive(:refresh_markdown_cache!).never

          is_expected.to eq('field_html')
        end
      end
    end
  end

  describe '#post_process' do
    let(:context_options) { {} }
    let(:html) { 'Consequatur aperiam et nesciunt modi aut assumenda quo id. '}
    let(:post_processed_html) { double(html_safe: 'safe doc') }
    let(:doc) { double(to_html: post_processed_html) }

    subject { renderer.post_process(html, context_options) }

    context 'when xhtml' do
      let(:context_options) { { xhtml: ' ' } }

      context 'without :post_process_pipeline key' do
        it 'uses PostProcessPipeline' do
          expect(::Banzai::Pipeline::PostProcessPipeline).to receive(:to_document).and_return(doc)

          subject
        end
      end

      context 'with :post_process_pipeline key' do
        let(:context_options) { { post_process_pipeline: Object, xhtml: ' ' } }

        it 'uses passed post process pipeline' do
          expect(Object).to receive(:to_document).and_return(doc)

          subject
        end
      end
    end

    context 'when not xhtml' do
      context 'without :post_process_pipeline key' do
        it 'uses PostProcessPipeline' do
          expect(::Banzai::Pipeline::PostProcessPipeline).to receive(:to_html)
            .with(html, { only_path: true, disable_asset_proxy: true })
            .and_return(post_processed_html)

          subject
        end
      end

      context 'with :post_process_pipeline key' do
        let(:context_options) { { post_process_pipeline: Object } }

        it 'uses passed post process pipeline' do
          expect(Object).to receive(:to_html).and_return(post_processed_html)

          subject
        end
      end
    end
  end
end
