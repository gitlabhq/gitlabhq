# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::Markup do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:blob) { fake_blob(path: 'CHANGELOG.md') }

  subject { described_class.new(blob) }

  describe '#banzai_render_context' do
    it 'returns context needed for banzai rendering' do
      expect(subject.banzai_render_context.keys).to eq([:cache_key])
    end

    context 'when blob does respond to rendered_markup' do
      before do
        allow(blob).to receive(:rendered_markup).and_return("some rendered markup")
      end

      it 'does sets rendered key' do
        expect(subject.banzai_render_context.keys).to include(:rendered)
      end
    end

    context 'when cached_markdown_blob feature flag is disabled' do
      before do
        stub_feature_flags(cached_markdown_blob: false)
      end

      it 'does not set cache_key key' do
        expect(subject.banzai_render_context.keys).not_to include(:cache_key)
      end
    end
  end
end
