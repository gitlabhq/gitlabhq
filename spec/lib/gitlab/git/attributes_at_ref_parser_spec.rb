# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::AttributesAtRefParser, :seed_helper do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  subject { described_class.new(repository, 'lfs') }

  it 'loads .gitattributes blob' do
    repository.raw # Initialize repository in advance since this also checks attributes

    expected_filter = 'filter=lfs diff=lfs merge=lfs'
    receive_blob = receive(:new).with(a_string_including(expected_filter))
    expect(Gitlab::Git::AttributesParser).to receive_blob.and_call_original

    subject
  end

  it 'handles missing blobs' do
    expect { described_class.new(repository, 'non-existent-branch') }.not_to raise_error
  end

  describe '#attributes' do
    it 'returns the attributes as a Hash' do
      expect(subject.attributes('test.lfs')['filter']).to eq('lfs')
    end
  end
end
