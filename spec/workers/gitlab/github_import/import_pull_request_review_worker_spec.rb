# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportPullRequestReviewWorker do
  it { is_expected.to include_module(Gitlab::GithubImport::ObjectImporter) }

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::PullRequestReview) }
  end

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::PullRequestReviewImporter) }
  end

  describe '#counter_name' do
    it { expect(subject.counter_name).to eq(:github_importer_imported_pull_request_reviews) }
  end

  describe '#counter_description' do
    it { expect(subject.counter_description).to eq('The number of imported GitHub pull request reviews') }
  end
end
