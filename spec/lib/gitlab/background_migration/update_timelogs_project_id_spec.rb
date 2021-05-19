# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateTimelogsProjectId, schema: 20210427212034 do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project1) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:project2) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:issue1) { table(:issues).create!(project_id: project1.id) }
  let!(:issue2) { table(:issues).create!(project_id: project2.id) }
  let!(:merge_request1) { table(:merge_requests).create!(target_project_id: project1.id, source_branch: 'master', target_branch: 'feature') }
  let!(:merge_request2) { table(:merge_requests).create!(target_project_id: project2.id, source_branch: 'master', target_branch: 'feature') }
  let!(:timelog1) { table(:timelogs).create!(issue_id: issue1.id, time_spent: 60) }
  let!(:timelog2) { table(:timelogs).create!(issue_id: issue1.id, time_spent: 60) }
  let!(:timelog3) { table(:timelogs).create!(issue_id: issue2.id, time_spent: 60) }
  let!(:timelog4) { table(:timelogs).create!(merge_request_id: merge_request1.id, time_spent: 600) }
  let!(:timelog5) { table(:timelogs).create!(merge_request_id: merge_request1.id, time_spent: 600) }
  let!(:timelog6) { table(:timelogs).create!(merge_request_id: merge_request2.id, time_spent: 600) }
  let!(:timelog7) { table(:timelogs).create!(issue_id: issue2.id, time_spent: 60, project_id: project1.id) }
  let!(:timelog8) { table(:timelogs).create!(merge_request_id: merge_request2.id, time_spent: 600, project_id: project1.id) }

  describe '#perform' do
    context 'when timelogs belong to issues' do
      it 'sets correct project_id' do
        subject.perform(timelog1.id, timelog3.id)

        expect(timelog1.reload.project_id).to eq(issue1.project_id)
        expect(timelog2.reload.project_id).to eq(issue1.project_id)
        expect(timelog3.reload.project_id).to eq(issue2.project_id)
      end
    end

    context 'when timelogs belong to merge requests' do
      it 'sets correct project ids' do
        subject.perform(timelog4.id, timelog6.id)

        expect(timelog4.reload.project_id).to eq(merge_request1.target_project_id)
        expect(timelog5.reload.project_id).to eq(merge_request1.target_project_id)
        expect(timelog6.reload.project_id).to eq(merge_request2.target_project_id)
      end
    end

    context 'when timelogs already belong to projects' do
      it 'does not update the project id' do
        subject.perform(timelog7.id, timelog8.id)

        expect(timelog7.reload.project_id).to eq(project1.id)
        expect(timelog8.reload.project_id).to eq(project1.id)
      end
    end
  end
end
