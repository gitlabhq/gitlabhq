# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::Markup do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:blob) { fake_blob(path: 'CHANGELOG.md') }

  subject { described_class.new(blob) }

  describe '#banzai_render_context' do
    it 'returns context needed for banzai rendering' do
      expect(subject.banzai_render_context.keys).to match_array([:issuable_reference_expansion_enabled, :cache_key])
      expect(subject.banzai_render_context[:issuable_reference_expansion_enabled]).to be(true)
    end

    context 'when blob does respond to rendered_markup' do
      before do
        allow(blob).to receive(:rendered_markup).and_return("some rendered markup")
      end

      it 'does sets rendered key' do
        expect(subject.banzai_render_context.keys).to include(:rendered)
      end
    end
  end
end
