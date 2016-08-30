require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeSaver, services: true do
  describe 'saves the project tree into a json object' do
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:project_tree_saver) { described_class.new(project: project, shared: shared) }
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:user) { create(:user) }
    let(:project) { setup_project }

    before do
      project.team << [user, :master]
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after do
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
        expect(saved_project_json).to include({ "visibility_level" => 20 })
      end

      it 'has milestones' do
        expect(saved_project_json['milestones']).not_to be_empty
      end

      it 'has merge requests' do
        expect(saved_project_json['merge_requests']).not_to be_empty
      end

      it 'has merge request\'s milestones' do
        expect(saved_project_json['merge_requests'].first['milestone']).not_to be_empty
      end

      it 'has events' do
        expect(saved_project_json['merge_requests'].first['milestone']['events']).not_to be_empty
      end

      it 'has snippets' do
        expect(saved_project_json['snippets']).not_to be_empty
      end

      it 'has snippet notes' do
        expect(saved_project_json['snippets'].first['notes']).not_to be_empty
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

      it 'has author on issue comments' do
        expect(saved_project_json['issues'].first['notes'].first['author']).not_to be_empty
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

      it 'has author on merge requests comments' do
        expect(saved_project_json['merge_requests'].first['notes'].first['author']).not_to be_empty
      end

      it 'has pipeline statuses' do
        expect(saved_project_json['pipelines'].first['statuses']).not_to be_empty
      end

      it 'has pipeline builds' do
        expect(saved_project_json['pipelines'].first['statuses'].count { |hash| hash['type'] == 'Ci::Build'}).to eq(1)
      end

      it 'has pipeline commits' do
        expect(saved_project_json['pipelines']).not_to be_empty
      end

      it 'has ci pipeline notes' do
        expect(saved_project_json['pipelines'].first['notes']).not_to be_empty
      end

      it 'has labels with no associations' do
        expect(saved_project_json['labels']).not_to be_empty
      end

      it 'has labels associated to records' do
        expect(saved_project_json['issues'].first['label_links'].first['label']).not_to be_empty
      end

      it 'does not complain about non UTF-8 characters in MR diffs' do
        ActiveRecord::Base.connection.execute("UPDATE merge_request_diffs SET st_diffs = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

        expect(project_tree_saver.save).to be true
      end
    end
  end

  def setup_project
    issue = create(:issue, assignee: user)
    snippet = create(:project_snippet)
    release = create(:release)

    project = create(:project,
                     :public,
                     issues: [issue],
                     snippets: [snippet],
                     releases: [release]
                    )
    label = create(:label, project: project)
    create(:label_link, label: label, target: issue)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone)
    commit_status = create(:commit_status, project: project)

    ci_pipeline = create(:ci_pipeline,
                       project: project,
                       sha: merge_request.diff_head_sha,
                       ref: merge_request.source_branch,
                       statuses: [commit_status])

    create(:ci_build, pipeline: ci_pipeline, project: project)
    create(:milestone, project: project)
    create(:note, noteable: issue, project: project)
    create(:note, noteable: merge_request, project: project)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
           author: user,
           project: project,
           commit_id: ci_pipeline.sha)

    create(:event, target: milestone, project: project, action: Event::CREATED, author: user)

    project
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end
end
