# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ObjectCounter, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project, :import_started, import_type: 'github', import_url: 'https://github.com/vim/vim.git') }

  it 'validates the operation being incremented' do
    expect { described_class.increment(project, :issue, :unknown) }
      .to raise_error(ArgumentError, 'operation must be fetched or imported')
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

  it 'does not increment the counter if the given value is <= 0' do
    expect(Gitlab::Metrics)
      .not_to receive(:counter)

    expect(Gitlab::Metrics)
      .not_to receive(:counter)

    described_class.increment(project, :issue, :fetched, value: 0)
    described_class.increment(project, :issue, :imported, value: nil)

    expect(described_class.summary(project)).to eq({
      'fetched' => {},
      'imported' => {}
    })
  end

  it 'expires etag cache of relevant realtime change endpoints on increment' do
    expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
      expect(instance).to receive(:touch).with(Gitlab::Routing.url_helpers.realtime_changes_import_github_path(format: :json))
    end

    described_class.increment(project, :issue, :fetched)
  end

  describe '.summary' do
    context 'when there are cached import statistics' do
      before do
        described_class.increment(project, :issue, :fetched, value: 10)
        described_class.increment(project, :issue, :imported, value: 8)
      end

      it 'includes cached object counts stats in response' do
        expect(described_class.summary(project)).to eq(
          'fetched' => { 'issue' => 10 },
          'imported' => { 'issue' => 8 }
        )
      end
    end

    context 'when there are no cached import statistics' do
      context 'when project import is in progress' do
        it 'includes an empty object counts stats in response' do
          expect(described_class.summary(project)).to eq(described_class::EMPTY_SUMMARY)
        end
      end

      context 'when project import is not in progress' do
        let(:checksums) do
          {
            'fetched' => {
              "issue" => 2,
              "label" => 10,
              "note" => 2,
              "protected_branch" => 2,
              "pull_request" => 2
            },
            "imported" => {
              "issue" => 2,
              "label" => 10,
              "note" => 2,
              "protected_branch" => 2,
              "pull_request" => 2
            }
          }
        end

        before do
          project.import_state.update_columns(checksums: checksums, status: :finished)
        end

        it 'includes project import checksums in response' do
          expect(described_class.summary(project)).to eq(checksums)
        end
      end
    end
  end
end
