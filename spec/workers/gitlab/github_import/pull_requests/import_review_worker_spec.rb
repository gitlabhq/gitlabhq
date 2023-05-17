# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::PullRequests::ImportReviewWorker, feature_category: :importers do
  it { is_expected.to include_module(Gitlab::GithubImport::ObjectImporter) }

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::PullRequestReview) }
  end

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::PullRequests::ReviewImporter) }
  end

  describe '#object_type' do
    it { expect(subject.object_type).to eq(:pull_request_review) }
  end
end
