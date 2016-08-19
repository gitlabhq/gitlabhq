require 'spec_helper'

describe ElasticIndexerWorker, elastic: true do
  include Gitlab::CurrentSettings
  subject { described_class.new }

  before do
    Elasticsearch::Model.client = Elasticsearch::Client.new(
      host: current_application_settings.elasticsearch_host,
      port: current_application_settings.elasticsearch_port
    )

    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index
  end

  Sidekiq::Testing.disable! do
    describe 'Indexing new records' do
      it 'indexes a project' do
        project = create :empty_project

        expect do
          subject.perform("index", "Project", project.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'indexes an issue' do
        issue = create :issue

        expect do
          subject.perform("index", "Issue", issue.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'indexes a note' do
        note = create :note

        expect do
          subject.perform("index", "Note", note.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'indexes a milestone' do
        milestone = create :milestone

        expect do
          subject.perform("index", "Milestone", milestone.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'indexes a merge request' do
        merge_request = create :merge_request

        expect do
          subject.perform("index", "MergeRequest", merge_request.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').records.size }.by(1)
      end
    end

    describe 'Updating index' do
      it 'updates a project' do
        project = create :empty_project
        subject.perform("index", "Project", project.id)
        project.update(name: "new")

        expect do
          subject.perform("update", "Project", project.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'updates an issue' do
        issue = create :issue
        subject.perform("index", "Issue", issue.id)
        issue.update(title: "new")

        expect do
          subject.perform("update", "Issue", issue.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'updates a note' do
        note = create :note
        subject.perform("index", "Note", note.id)
        note.update(note: 'new')

        expect do
          subject.perform("update", "Note", note.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'updates a milestone' do
        milestone = create :milestone
        subject.perform("index", "Milestone", milestone.id)
        milestone.update(title: 'new')

        expect do
          subject.perform("update", "Milestone", milestone.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'updates a merge request' do
        merge_request = create :merge_request
        subject.perform("index", "MergeRequest", merge_request.id)
        merge_request.update(title: 'new')

        expect do
          subject.perform("index", "MergeRequest", merge_request.id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('new').records.size }.by(1)
      end
    end

    describe 'Delete' do
      it 'deletes a project with all nested objects' do
        project = create :project
        subject.perform("index", "Project", project.id)

        issue = create :issue, project: project
        subject.perform("index", "Issue", issue.id)

        milestone = create :milestone, project: project
        subject.perform("index", "Milestone", milestone.id)

        note = create :note, project: project
        subject.perform("index", "Note", note.id)

        merge_request = create :merge_request, target_project: project, source_project: project
        subject.perform("index", "MergeRequest", merge_request.id)

        ElasticCommitIndexerWorker.new.perform(project.id)
        Gitlab::Elastic::Helper.refresh_index

        ## All database objects + data from repository. The absolute value does not matter
        expect(Elasticsearch::Model.search('*').total_count).to be > 40

        subject.perform("delete", "Project", project.id)
        Gitlab::Elastic::Helper.refresh_index

        expect(Elasticsearch::Model.search('*').total_count).to be(0)
      end

      it 'deletes an issue' do
        issue = create :issue
        subject.perform("index", "Issue", issue.id)
        Gitlab::Elastic::Helper.refresh_index

        issue.destroy

        expect do
          subject.perform("delete", "Issue", issue.id, "project_id" => issue.project_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').total_count }.by(-1)
      end

      it 'deletes a note' do
        note = create :note
        subject.perform("index", "Note", note.id)
        Gitlab::Elastic::Helper.refresh_index

        note.destroy

        expect do
          subject.perform("delete", "Note", note.id, "project_id" => note.project_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').total_count }.by(-1)
      end

      it 'deletes a milestone' do
        milestone = create :milestone
        subject.perform("index", "Milestone", milestone.id)
        Gitlab::Elastic::Helper.refresh_index

        milestone.destroy

        expect do
          subject.perform("delete", "Milestone", milestone.id, "project_id" => milestone.project_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').total_count }.by(-1)
      end

      it 'deletes a merge request' do
        merge_request = create :merge_request
        subject.perform("index", "MergeRequest", merge_request.id)
        Gitlab::Elastic::Helper.refresh_index

        merge_request.destroy

        expect do
          subject.perform("delete", "MergeRequest", merge_request.id, "project_id" => merge_request.target_project_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change{ Elasticsearch::Model.search('*').total_count }.by(-1)
      end
    end
  end
end
