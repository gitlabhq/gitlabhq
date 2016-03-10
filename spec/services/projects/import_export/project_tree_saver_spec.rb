require 'spec_helper'

describe Projects::ImportExport::ProjectTreeSaver, services: true do
  describe :save do

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
             releases: [release],
             commit_statuses: [commit_status])
    end
    let!(:milestone) { create(:milestone, title: "Milestone v1.2", project: project) }
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:shared) { Projects::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:project_tree_saver) { Projects::ImportExport::ProjectTreeSaver.new(project: project, shared: shared) }

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

      it 'has commit statuses' do
        expect(saved_project_json['commit_statuses']).not_to be_empty
      end

      it 'has project members' do
        expect(saved_project_json['project_members']).not_to be_empty
      end
    end
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end

  # TODO: Remove this. Current JSON pretty printed:
  # {
  # "id":7,
  #   "name":"searchable_project",
  #   "path":"gitlabhq",
  #   "description":null,
  # "issues_enabled":true,
  # "wall_enabled":false,
  # "merge_requests_enabled":true,
  # "wiki_enabled":true,
  # "snippets_enabled":true,
  # "visibility_level":20,
  #   "archived":false,
  # "issues":[
  #   {
  #     "id":1,
  #     "title":"Voluptas dolores molestias iste excepturi quia atque sint et.",
  #     "assignee_id":1,
  #     "author_id":2,
  #     "project_id":7,
  #     "created_at":"2016-03-08T09:14:31.726Z",
  #     "updated_at":"2016-03-08T09:14:36.293Z",
  #     "position":0,
  #     "branch_name":null,
  #     "description":null,
  #     "milestone_id":null,
  #     "state":"opened",
  #     "iid":1,
  #     "updated_by_id":null
  #   }
  # ],
  #   "merge_requests":[
  #   {
  #     "id":1,
  #     "target_branch":"feature",
  #     "source_branch":"master",
  #     "source_project_id":2,
  #     "author_id":5,
  #     "assignee_id":null,
  #     "title":"Quam velit cupiditate culpa perspiciatis esse maiores quaerat.",
  #     "created_at":"2016-03-08T09:14:32.597Z",
  #     "updated_at":"2016-03-08T09:14:32.597Z",
  #     "milestone_id":null,
  #     "state":"opened",
  #     "merge_status":"can_be_merged",
  #     "target_project_id":7,
  #     "iid":1,
  #     "description":null,
  #     "position":0,
  #     "locked_at":null,
  #     "updated_by_id":null,
  #     "merge_error":null,
  #     "merge_params":{
  #
  #     },
  #     "merge_when_build_succeeds":false,
  #     "merge_user_id":null,
  #     "merge_commit_sha":null
  #   }
  # ],
  #   "labels":[
  #   {
  #     "id":1,
  #     "title":"Bug",
  #     "color":"#990000",
  #     "project_id":7,
  #     "created_at":"2016-03-08T09:14:33.774Z",
  #     "updated_at":"2016-03-08T09:14:36.314Z",
  #     "template":false,
  #     "description":null
  #   }
  # ],
  #   "milestones":[
  #   {
  #     "id":1,
  #     "title":"Milestone v1.2",
  #     "project_id":7,
  #     "description":null,
  #     "due_date":null,
  #     "created_at":"2016-03-08T09:14:36.526Z",
  #     "updated_at":"2016-03-08T09:14:36.526Z",
  #     "state":"active",
  #     "iid":1
  #   }
  # ],
  #   "snippets":[
  #   {
  #     "id":1,
  #     "title":"Voluptatem qui officiis modi ut fugit distinctio dolor qui.",
  #     "content":"Quaerat sunt eligendi voluptatum magnam.",
  #     "author_id":12,
  #     "project_id":7,
  #     "created_at":"2016-03-08T09:14:34.539Z",
  #     "updated_at":"2016-03-08T09:14:36.332Z",
  #     "file_name":"rowland.tremblay",
  #     "expires_at":null,
  #     "visibility_level":0
  #   }
  # ],
  #   "releases":[
  #   {
  #     "id":1,
  #     "tag":"v1.1.0",
  #     "description":"Awesome release",
  #     "project_id":7,
  #     "created_at":"2016-03-08T09:14:35.023Z",
  #     "updated_at":"2016-03-08T09:14:36.351Z"
  #   }
  # ],
  #   "events":[
  #   {
  #     "id":1,
  #     "target_type":null,
  #     "target_id":null,
  #     "title":null,
  #     "data":null,
  #     "project_id":7,
  #     "created_at":"2016-03-08T09:14:36.806Z",
  #     "updated_at":"2016-03-08T09:14:36.806Z",
  #     "action":8,
  #     "author_id":1
  #   }
  # ],
  #   "commit_statuses":[
  #   {
  #     "id":1,
  #     "project_id":null,
  #     "status":"success",
  #     "finished_at":"2016-01-26T07:23:42.000Z",
  #     "trace":null,
  #     "created_at":"2016-03-08T09:14:35.633Z",
  #     "updated_at":"2016-03-08T09:14:36.385Z",
  #     "started_at":"2016-01-26T07:21:42.000Z",
  #     "runner_id":null,
  #     "coverage":null,
  #     "commit_id":1,
  #     "commands":null,
  #     "job_id":null,
  #     "name":"default",
  #     "deploy":false,
  #     "options":null,
  #     "allow_failure":false,
  #     "stage":null,
  #     "trigger_request_id":null,
  #     "stage_idx":null,
  #     "tag":null,
  #     "ref":null,
  #     "user_id":null,
  #     "target_url":null,
  #     "description":"commit status",
  #     "artifacts_file":null,
  #     "gl_project_id":7,
  #     "artifacts_metadata":null,
  #     "erased_by_id":null,
  #     "erased_at":null
  #   }
  # ]
  # }
end
