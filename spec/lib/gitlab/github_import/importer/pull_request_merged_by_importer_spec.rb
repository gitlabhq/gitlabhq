# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestMergedByImporter, :clean_gitlab_redis_cache do
  let_it_be(:merge_request) { create(:merged_merge_request) }

  let(:project) { merge_request.project }
  let(:merged_at) { Time.new(2017, 1, 1, 12, 00).utc }
  let(:client_double) { double(user: double(id: 999, login: 'merger', email: 'merger@email.com')) }
  let(:merger_user) { double(id: 999, login: 'merger') }

  let(:pull_request) do
    instance_double(
      Gitlab::GithubImport::Representation::PullRequest,
      iid: merge_request.iid,
      merged_at: merged_at,
      merged_by: merger_user
    )
  end

  subject { described_class.new(pull_request, project, client_double) }

  context 'when the merger user can be mapped' do
    it 'assigns the merged by user when mapped' do
      merge_user = create(:user, email: 'merger@email.com')

      subject.execute

      metrics = merge_request.metrics.reload
      expect(metrics.merged_by).to eq(merge_user)
      expect(metrics.merged_at).to eq(merged_at)
    end
  end

  context 'when the merger user cannot be mapped to a gitlab user' do
    it 'adds a note referencing the merger user' do
      expect { subject.execute }
        .to change(Note, :count).by(1)
        .and not_change(merge_request, :updated_at)

      metrics = merge_request.metrics.reload
      expect(metrics.merged_by).to be_nil
      expect(metrics.merged_at).to eq(merged_at)

      last_note = merge_request.notes.last
      expect(last_note.note).to eq("*Merged by: merger at 2017-01-01 12:00:00 UTC*")
      expect(last_note.created_at).to eq(merged_at)
      expect(last_note.author).to eq(project.creator)
    end
  end

  context 'when the merger user is not provided' do
    let(:merger_user) { nil }

    it 'adds a note referencing the merger user' do
      expect { subject.execute }
        .to change(Note, :count).by(1)
        .and not_change(merge_request, :updated_at)

      metrics = merge_request.metrics.reload
      expect(metrics.merged_by).to be_nil
      expect(metrics.merged_at).to eq(merged_at)

      last_note = merge_request.notes.last
      expect(last_note.note).to eq("*Merged by: ghost at 2017-01-01 12:00:00 UTC*")
      expect(last_note.created_at).to eq(merged_at)
      expect(last_note.author).to eq(project.creator)
    end
  end
end
