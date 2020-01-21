# frozen_string_literal: true

require 'spec_helper'

describe BlobViewer::RouteMap do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-MAP.strip_heredoc
      # Team data
      - source: 'data/team.yml'
        public: 'team/'
    MAP
  end
  let(:blob) { fake_blob(path: '.gitlab/route-map.yml', data: data) }

  subject { described_class.new(blob) }

  describe '#validation_message' do
    it 'calls prepare! on the viewer' do
      expect(subject).to receive(:prepare!)

      subject.validation_message
    end

    context 'when the configuration is valid' do
      it 'returns nil' do
        expect(subject.validation_message).to be_nil
      end
    end

    context 'when the configuration is invalid' do
      let(:data) { 'oof' }

      it 'returns the error message' do
        expect(subject.validation_message).to eq('Route map is not an array')
      end
    end
  end
end
