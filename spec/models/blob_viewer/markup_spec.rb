# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::Markup, :aggregate_failures, feature_category: :markdown do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:blob) { fake_blob(path: 'CHANGELOG.md') }

  subject { described_class.new(blob) }

  describe '#banzai_render_context' do
    context 'when blob container is a Project' do
      it 'does not include use_filename_in_anchor' do
        expect(subject.banzai_render_context.keys).to match_array(
          [:project, :requested_path, :issuable_reference_expansion_enabled, :cache_key, :commit_id]
        )
        expect(subject.banzai_render_context[:project]).to eq(project)
        expect(subject.banzai_render_context[:requested_path]).to eq('CHANGELOG.md')
        expect(subject.banzai_render_context[:issuable_reference_expansion_enabled]).to be(true)
        expect(subject.banzai_render_context[:commit_id]).to eq(blob.commit_id)
      end
    end

    context 'when blob container is a Snippet' do
      let(:snippet) { build_stubbed(:project_snippet) }
      let(:blob) { fake_blob(path: 'CHANGELOG.md', container: snippet) }

      it 'includes use_filename_in_anchor: true' do
        expect(subject.banzai_render_context[:use_filename_in_anchor]).to be(true)
      end
    end

    context 'when blob container is nil' do
      let(:blob) { fake_blob(path: 'CHANGELOG.md', container: nil) }

      it 'does not include use_filename_in_anchor' do
        expect(subject.banzai_render_context).not_to have_key(:use_filename_in_anchor)
      end
    end
  end
end
