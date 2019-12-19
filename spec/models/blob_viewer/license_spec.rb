# frozen_string_literal: true

require 'spec_helper'

describe BlobViewer::License do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:blob) { fake_blob(path: 'LICENSE') }

  subject { described_class.new(blob) }

  describe '#license' do
    it 'returns the blob project repository license' do
      expect(subject.license).not_to be_nil
      expect(subject.license).to eq(project.repository.license)
    end
  end

  describe '#render_error' do
    context 'when there is no license' do
      before do
        allow(project.repository).to receive(:license).and_return(nil)
      end

      it 'returns :unknown_license' do
        expect(subject.render_error).to eq(:unknown_license)
      end
    end

    context 'when there is a license' do
      it 'returns nil' do
        expect(subject.render_error).to be_nil
      end
    end
  end
end
