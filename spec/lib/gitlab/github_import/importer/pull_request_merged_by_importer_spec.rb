# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestMergedByImporter, :clean_gitlab_redis_cache do
  let_it_be(:merge_request) { create(:merged_merge_request) }
  let(:project) { merge_request.project }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00).utc }
  let(:client_double) { double(user: double(id: 999, login: 'merger', email: 'merger@email.com')) }

  let(:pull_request) do
    instance_double(
      Gitlab::GithubImport::Representation::PullRequest,
      iid: merge_request.iid,
      created_at: created_at,
      merged_by: double(id: 999, login: 'merger')
    )
  end

  subject { described_class.new(pull_request, project, client_double) }

  it 'assigns the merged by user when mapped' do
    merge_user = create(:user, email: 'merger@email.com')

    subject.execute

    expect(merge_request.metrics.reload.merged_by).to eq(merge_user)
  end

  it 'adds a note referencing the merger user when the user cannot be mapped' do
    expect { subject.execute }
      .to change(Note, :count).by(1)
      .and not_change(merge_request, :updated_at)

    last_note = merge_request.notes.last

    expect(last_note.note).to eq("*Merged by: merger*")
    expect(last_note.created_at).to eq(created_at)
    expect(last_note.author).to eq(project.creator)
  end
end
