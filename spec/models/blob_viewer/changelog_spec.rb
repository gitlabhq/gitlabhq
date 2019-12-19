# frozen_string_literal: true

require 'spec_helper'

describe BlobViewer::Changelog do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:blob) { fake_blob(path: 'CHANGELOG') }

  subject { described_class.new(blob) }

  describe '#render_error' do
    context 'when there are no tags' do
      before do
        allow(project.repository).to receive(:tag_count).and_return(0)
      end

      it 'returns :no_tags' do
        expect(subject.render_error).to eq(:no_tags)
      end
    end

    context 'when there are tags' do
      it 'returns nil' do
        expect(subject.render_error).to be_nil
      end
    end
  end
end
