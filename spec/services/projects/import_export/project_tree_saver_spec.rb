require 'spec_helper'

describe Projects::ImportExport::ProjectTreeSaver, services: true do
  describe :save do

    let(:user) { create(:user) }
    let(:issue) { create(:issue, assignee: user) }
    let!(:project) { create(:project, :public, name: 'searchable_project', issues: [issue] )}
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:project_tree_saver) { Projects::ImportExport::ProjectTreeSaver.new(project: project) }

    before(:each) do
      project.team << [user, :master]
      allow_any_instance_of(Projects::ImportExport::ProjectTreeSaver).to receive(:export_path).and_return(export_path)
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

      it 'has issues' do
        expect(saved_project_json['issues']).not_to be_empty
      end
    end
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end

  # TODO: Remove this. Current JSON pretty printed:
  # {
  # "id": 1,
  #   "name": "searchable_project",
  #   "path": "gitlabhq",
  #   "description": null,
  # "issues_enabled": true,
  # "wall_enabled": false,
  # "merge_requests_enabled": true,
  # "wiki_enabled": true,
  # "snippets_enabled": true,
  # "visibility_level": 20,
  #   "archived": false,
  # "issues": [
  #
  # ],
  #   "merge_requests": [
  #
  # ],
  #   "labels": [
  #
  # ],
  #   "milestones": [
  #
  # ],
  #   "snippets": [
  #
  # ],
  #   "releases": [
  #
  # ],
  #   "events": [
  #   {
  #     "id": 1,
  #     "target_type": null,
  #     "target_id": null,
  #     "title": null,
  #     "data": null,
  #     "project_id": 1,
  #     "created_at": "2016-03-07T17:05:20.926Z",
  #     "updated_at": "2016-03-07T17:05:20.926Z",
  #     "action": 8,
  #     "author_id": 3
  #   }
  # ],
  #   "commit_statuses": [
  #
  # ]
  # }
end
