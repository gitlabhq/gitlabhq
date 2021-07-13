# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ObjectCounter, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }

  it 'validates the operation being incremented' do
    expect { described_class.increment(project, :issue, :unknown) }
      .to raise_error(ArgumentError, 'Operation must be fetched or imported')
  end

  it 'increments the counter and saves the key to be listed in the summary later' do
    expect(Gitlab::Metrics)
      .to receive(:counter)
      .twice
      .with(:github_importer_fetched_issue, 'The number of fetched Github Issue')
      .and_return(double(increment: true))

    expect(Gitlab::Metrics)
      .to receive(:counter)
      .twice
      .with(:github_importer_imported_issue, 'The number of imported Github Issue')
      .and_return(double(increment: true))

    described_class.increment(project, :issue, :fetched)
    described_class.increment(project, :issue, :fetched)
    described_class.increment(project, :issue, :imported)
    described_class.increment(project, :issue, :imported)

    expect(described_class.summary(project)).to eq({
      'fetched' => { 'issue' => 2 },
      'imported' => { 'issue' => 2 }
    })
  end
end
