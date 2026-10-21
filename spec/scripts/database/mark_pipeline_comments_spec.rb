# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../scripts/database/mark_pipeline_comments'

RSpec.describe MarkPipelineComments, feature_category: :database do
  let(:merge_request_id) { '123' }
  let(:project_path) { 'gitlab-org/gitlab' }
  # The gitlab gem's client, not this app's Gitlab module, so the constant does not resolve here.
  let(:client) { double('Gitlab::Client') } # rubocop:disable RSpec/VerifiedDoubles -- gem class is not loaded
  let(:env) do
    {
      'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => 'my-branch',
      'CI_REPOSITORY_URL' => 'https://gitlab-ci-token:token@gitlab.com/gitlab-org/gitlab.git'
    }
  end

  # The source branch tip, as an epoch. Notes created before it are stale.
  let(:tip_epoch) { Time.utc(2026, 10, 20, 12, 0, 0).to_i }

  let(:tagged_note_body) { "results <!-- #{described_class::DB_PIPELINE_NOTE_TAG} -->" }
  let(:timestamp_override) { tip_epoch.to_s }

  def note(id:, created_at:, body: tagged_note_body)
    double(id: id, created_at: created_at, body: body) # rubocop:disable RSpec/VerifiedDoubles -- Gitlab::ObjectifiedHash
  end

  def stub_notes(notes)
    allow(client).to receive(:merge_request_notes)
      .with(project_path, merge_request_id)
      .and_return(double(auto_paginate: notes)) # rubocop:disable RSpec/VerifiedDoubles -- paginated response
  end

  subject(:marker) do
    described_class.new(
      merge_request_id: merge_request_id,
      project_path: project_path,
      client: client,
      env: env,
      timestamp_override: timestamp_override
    )
  end

  describe '#execute' do
    context 'when a tagged note predates the most recent commit' do
      it 'annotates the note as invalidated' do
        stub_notes([note(id: 7, created_at: '2026-10-19T00:00:00Z')])

        expect(client).to receive(:edit_merge_request_note)
          .with(project_path, merge_request_id, 7, a_string_starting_with(described_class::INVALIDATED_RESULTS_MSG))

        marker.execute
      end
    end

    context 'when a tagged note is newer than the most recent commit' do
      it 'leaves the note alone' do
        stub_notes([note(id: 7, created_at: '2026-10-21T00:00:00Z')])

        expect(client).not_to receive(:edit_merge_request_note)

        marker.execute
      end
    end

    context 'when the note carries no database-testing tag' do
      it 'leaves the note alone' do
        stub_notes([note(id: 7, created_at: '2026-10-19T00:00:00Z', body: 'an unrelated comment')])

        expect(client).not_to receive(:edit_merge_request_note)

        marker.execute
      end
    end

    context 'when the note has already been invalidated' do
      it 'does not annotate it twice' do
        body = "#{tagged_note_body} <!-- #{described_class::INVALIDATED_RESULTS_MSG_TAG} -->"
        stub_notes([note(id: 7, created_at: '2026-10-19T00:00:00Z', body: body)])

        expect(client).not_to receive(:edit_merge_request_note)

        marker.execute
      end
    end
  end

  describe 'resolving the most recent commit timestamp' do
    let(:ref) { 'refs/remotes/origin/my-branch' }

    context 'with a timestamp override' do
      it 'uses it and performs no git work' do
        stub_notes([note(id: 7, created_at: '2026-10-19T00:00:00Z')])

        expect(marker).not_to receive(:system)
        expect(Open3).not_to receive(:capture2)
        allow(client).to receive(:edit_merge_request_note)

        marker.execute
      end
    end

    context 'without a timestamp override' do
      let(:timestamp_override) { nil }

      before do
        stub_notes([note(id: 7, created_at: '2026-10-19T00:00:00Z')])
        allow(client).to receive(:edit_merge_request_note)
      end

      it 'shallow-fetches the source branch and reads the tip timestamp' do
        expect(marker).to receive(:system).with(
          'git', 'fetch', '--depth=1', env['CI_REPOSITORY_URL'], "+my-branch:#{ref}", out: File::NULL
        ).and_return(true)

        expect(Open3).to receive(:capture2)
          .with('git', 'log', '-1', '--format=%at', ref)
          .and_return(["#{tip_epoch}\n", instance_double(Process::Status, success?: true)])

        marker.execute
      end

      it 'resolves once even when several notes are examined' do
        stub_notes(
          [
            note(id: 7, created_at: '2026-10-19T00:00:00Z'),
            note(id: 8, created_at: '2026-10-19T01:00:00Z')
          ]
        )

        expect(marker).to receive(:system).once.and_return(true)
        expect(Open3).to receive(:capture2).once.and_return(
          ["#{tip_epoch}\n", instance_double(Process::Status, success?: true)]
        )

        marker.execute
      end

      it 'raises when the fetch fails' do
        allow(marker).to receive(:system).and_return(false)

        expect { marker.execute }.to raise_error(/Failed to fetch my-branch/)
      end

      # An empty or failed read would become Time.at(0); since no note predates 1970 that would
      # silently invalidate nothing, so it has to fail loudly instead.
      it 'raises when the timestamp read fails' do
        allow(marker).to receive(:system).and_return(true)
        allow(Open3).to receive(:capture2)
          .and_return(['', instance_double(Process::Status, success?: false)])

        expect { marker.execute }.to raise_error(/Failed to read the commit timestamp/)
      end

      it 'raises when the timestamp read returns nothing' do
        allow(marker).to receive(:system).and_return(true)
        allow(Open3).to receive(:capture2)
          .and_return([" \n", instance_double(Process::Status, success?: true)])

        expect { marker.execute }.to raise_error(/Failed to read the commit timestamp/)
      end
    end
  end
end
