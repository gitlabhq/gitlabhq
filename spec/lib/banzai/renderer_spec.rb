# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Renderer do
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
    let(:renderer) { described_class }

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
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
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
end
