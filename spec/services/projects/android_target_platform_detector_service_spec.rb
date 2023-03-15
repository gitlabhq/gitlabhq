# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AndroidTargetPlatformDetectorService, feature_category: :projects do
  let_it_be(:project) { build(:project) }

  subject { described_class.new(project).execute }

  before do
    allow(Gitlab::FileFinder).to receive(:new) { finder }
  end

  context 'when project is not an Android project' do
    let(:finder) { instance_double(Gitlab::FileFinder, find: []) }

    it { is_expected.to be_nil }
  end

  context 'when project is an Android project' do
    let(:finder) { instance_double(Gitlab::FileFinder) }

    before do
      query = described_class::MANIFEST_FILE_SEARCH_QUERY
      allow(finder).to receive(:find).with(query) { [instance_double(Gitlab::Search::FoundBlob)] }
    end

    it { is_expected.to eq :android }
  end
end
