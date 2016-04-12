require 'spec_helper'

describe Projects::ImportExport::ProjectTreeSaver, services: true do
  describe :save do

    # TODO refactor this into a setup method

    let(:user) { create(:user) }
    let(:issue) { create(:issue, assignee: user) }
    let(:merge_request) { create(:merge_request) }
    let(:label) { create(:label) }
    let(:snippet) { create(:project_snippet) }
    let(:commit_status) { create(:commit_status) }
    let(:release) { create(:release) }
    let!(:project) do
      create(:project,
             :public,
             name: 'searchable_project',
             issues: [issue],
             merge_requests: [merge_request],
             labels: [label],
             snippets: [snippet],
             releases: [release]
             )
    end
    let!(:ci_commit) { create(:ci_commit, project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch, statuses: [commit_status]) }
    let!(:milestone) { create(:milestone, title: "Milestone v1.2", project: project) }
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:shared) { Projects::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:project_tree_saver) { Projects::ImportExport::ProjectTreeSaver.new(project: project, shared: shared) }
    let!(:issue_note) { create(:note, note: ":+1: issue", noteable: issue) }
    let!(:merge_request_note) { create(:note, note: ":+1: merge_request", noteable: merge_request) }

    before(:each) do
      project.team << [user, :master]
      allow_any_instance_of(Projects::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after(:each) do
      FileUtils.rm_rf(export_path)
    end

    it 'saves project successfully' do
      expect(project_tree_saver.save).to be true
    end

    context 'JSON' do

      let(:saved_project_json) do
        project_tree_saver.save
        project_json(project_tree_saver.full_path)
      end

      it 'saves the correct json' do
        expect(saved_project_json).to include({ "name" => project.name })
      end

      it 'has events' do
        expect(saved_project_json['events']).not_to be_empty
      end

      it 'has milestones' do
        expect(saved_project_json['milestones']).not_to be_empty
      end

      it 'has merge requests' do
        expect(saved_project_json['merge_requests']).not_to be_empty
      end

      it 'has labels' do
        expect(saved_project_json['labels']).not_to be_empty
      end

      it 'has snippets' do
        expect(saved_project_json['snippets']).not_to be_empty
      end

      it 'has releases' do
        expect(saved_project_json['releases']).not_to be_empty
      end

      it 'has issues' do
        expect(saved_project_json['issues']).not_to be_empty
      end

      it 'has issue comments' do
        expect(saved_project_json['issues'].first['notes']).not_to be_empty
      end

      it 'has project members' do
        expect(saved_project_json['project_members']).not_to be_empty
      end

      it 'has merge requests diffs' do
        expect(saved_project_json['merge_requests'].first['merge_request_diff']).not_to be_empty
      end

      it 'has merge requests comments' do
        expect(saved_project_json['merge_requests'].first['notes']).not_to be_empty
      end

      it 'has commit statuses' do
        expect(saved_project_json['ci_commits'].first['statuses']).not_to be_empty
      end

      it 'has ci commits' do
        expect(saved_project_json['ci_commits']).not_to be_empty
      end
    end
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end
end
