# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::Notes::CreateService, feature_category: :importers do
  it 'does not support quick actions' do
    project = create(:project, :repository)
    user = create(:user)
    merge_request = create(:merge_request, source_project: project)

    project.add_maintainer(user)

    note = described_class.new(
      project,
      user,
      note: '/close',
      noteable_type: 'MergeRequest',
      noteable_id: merge_request.id
    ).execute

    expect(note.note).to eq('/close')
    expect(note.noteable.closed?).to be(false)
  end
end
