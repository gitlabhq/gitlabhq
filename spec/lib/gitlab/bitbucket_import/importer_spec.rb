# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BitbucketImport::Importer do
  include ImportSpecHelper

  before do
    stub_omniauth_provider('bitbucket')
    stub_feature_flags(stricter_mr_branch_name: false)
  end

  let(:statuses) do
    [
      "open",
      "resolved",
      "on hold",
      "invalid",
      "duplicate",
      "wontfix",
      "closed" # undocumented status
    ]
  end

  let(:reporters) do
    [
      nil,
      { "nickname" => "reporter1" },
      nil,
      { "nickname" => "reporter2" },
      { "nickname" => "reporter1" },
      nil,
      { "nickname" => "reporter3" }
    ]
  end

  let(:sample_issues_statuses) do
    issues = []

    statuses.map.with_index do |status, index|
      issues << {
        id: index,
        state: status,
        title: "Issue #{index}",
        kind: 'bug',
        content: {
            raw: "Some content to issue #{index}",
            markup: "markdown",
            html: "Some content to issue #{index}"
        }
      }
    end

    reporters.map.with_index do |reporter, index|
      issues[index]['reporter'] = reporter
    end

    issues
  end

  let(:project_identifier) { 'namespace/repo' }

  let(:data) do
    {
      'bb_session' => {
        'bitbucket_token' => "123456",
        'bitbucket_refresh_token' => "secret"
      }
    }
  end

  let(:project) do
    create(
      :project,
      :repository,
      import_source: project_identifier,
      import_url: "https://bitbucket.org/#{project_identifier}.git",
      import_data_attributes: { credentials: data }
    )
  end

  let(:importer) { described_class.new(project) }
  let(:gitlab_shell) { double }

  let(:issues_statuses_sample_data) do
    {
      count: sample_issues_statuses.count,
      values: sample_issues_statuses
    }
  end

  let(:sample) { RepoHelpers.sample_compare }

  before do
    allow(importer).to receive(:gitlab_shell) { gitlab_shell }
  end

  subject { described_class.new(project) }

  describe '#import_pull_requests' do
    let(:source_branch_sha) { sample.commits.last }
    let(:target_branch_sha) { sample.commits.first }
    let(:pull_request) do
      instance_double(
        Bitbucket::Representation::PullRequest,
        iid: 10,
        source_branch_sha: source_branch_sha,
        source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
        target_branch_sha: target_branch_sha,
        target_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.target_branch,
        title: 'This is a title',
        description: 'This is a test pull request',
        state: 'merged',
        author: 'other',
        created_at: Time.now,
        updated_at: Time.now)
    end
    let(:author_line) { "*Created by: someuser*\n\n" }

    before do
      allow(subject).to receive(:import_wiki)
      allow(subject).to receive(:import_issues)

      # https://gitlab.com/gitlab-org/gitlab-test/compare/c1acaa58bbcbc3eafe538cb8274ba387047b69f8...5937ac0a7beb003549fc5fd26fc247ad
      @inline_note = instance_double(
        Bitbucket::Representation::PullRequestComment,
        iid: 2,
        file_path: '.gitmodules',
        old_pos: nil,
        new_pos: 4,
        note: 'Hello world',
        author: 'someuser',
        created_at: Time.now,
        updated_at: Time.now,
        inline?: true,
        has_parent?: false)

      @reply = instance_double(
        Bitbucket::Representation::PullRequestComment,
        iid: 3,
        file_path: '.gitmodules',
        note: 'Hello world',
        author: 'someuser',
        created_at: Time.now,
        updated_at: Time.now,
        inline?: true,
        has_parent?: true,
        parent_id: 2)

      comments = [@inline_note, @reply]

      allow(subject.client).to receive(:repo)
      allow(subject.client).to receive(:pull_requests).and_return([pull_request])
      allow(subject.client).to receive(:pull_request_comments).with(anything, pull_request.iid).and_return(comments)
    end

    it 'imports threaded discussions' do
      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.state).to eq('merged')
      expect(merge_request.notes.count).to eq(2)
      expect(merge_request.notes.map(&:discussion_id).uniq.count).to eq(1)

      notes = merge_request.notes.order(:id).to_a
      start_note = notes.first
      expect(start_note).to be_a(DiffNote)
      expect(start_note.note).to include(@inline_note.note)
      expect(start_note.note).to include(author_line)

      reply_note = notes.last
      expect(reply_note).to be_a(DiffNote)
      expect(reply_note.note).to include(@reply.note)
      expect(reply_note.note).to include(author_line)
    end

    context 'when user exists in GitLab' do
      let!(:existing_user) { create(:user, username: 'someuser') }
      let!(:identity) { create(:identity, provider: 'bitbucket', extern_uid: existing_user.username, user: existing_user) }

      it 'does not add author line to comments' do
        expect { subject.execute }.to change { MergeRequest.count }.by(1)

        merge_request = MergeRequest.first

        notes = merge_request.notes.order(:id).to_a
        start_note = notes.first
        expect(start_note.note).to eq(@inline_note.note)
        expect(start_note.note).not_to include(author_line)

        reply_note = notes.last
        expect(reply_note.note).to eq(@reply.note)
        expect(reply_note.note).not_to include(author_line)
      end
    end

    context 'when importing a pull request throws an exception' do
      before do
        allow(pull_request).to receive(:raw).and_return('hello world')
        allow(subject.client).to receive(:pull_request_comments).and_raise(Gitlab::HTTP::Error)
      end

      it 'logs an error without the backtrace' do
        subject.execute

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.keys).to match_array(%i(type iid errors))
      end
    end

    context "when branches' sha is not found in the repository" do
      let(:source_branch_sha) { 'a' * Commit::MIN_SHA_LENGTH }
      let(:target_branch_sha) { 'b' * Commit::MIN_SHA_LENGTH }

      it 'uses the pull request sha references' do
        expect { subject.execute }.to change { MergeRequest.count }.by(1)

        merge_request_diff = MergeRequest.first.merge_request_diff
        expect(merge_request_diff.head_commit_sha).to eq source_branch_sha
        expect(merge_request_diff.start_commit_sha).to eq target_branch_sha
      end
    end
  end

  context 'issues statuses' do
    before do
      # HACK: Bitbucket::Representation.const_get('Issue') seems to return ::Issue without this
      Bitbucket::Representation::Issue.new({})

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: { has_issues: true, full_name: project_identifier }.to_json)

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/issues?pagelen=50&sort=created_on"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: issues_statuses_sample_data.to_json)

      stub_request(:get, "https://api.bitbucket.org/2.0/repositories/namespace/repo?pagelen=50&sort=created_on")
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'Bearer', 'User-Agent' => 'Faraday v0.9.2' })
        .to_return(status: 200, body: "", headers: {})

      sample_issues_statuses.each_with_index do |issue, index|
        stub_request(
          :get,
          "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/issues/#{issue[:id]}/comments?pagelen=50&sort=created_on"
        ).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: { author_info: { username: "username" }, utc_created_on: index }.to_json
        )
      end

      stub_request(
        :get,
        "https://api.bitbucket.org/2.0/repositories/#{project_identifier}/pullrequests?pagelen=50&sort=created_on&state=ALL"
      ).to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: {}.to_json)
    end

    context 'creating labels on project' do
      before do
        allow(importer).to receive(:import_wiki)
      end

      it 'creates labels as expected' do
        expect { importer.execute }.to change { Label.count }.from(0).to(Gitlab::BitbucketImport::Importer::LABELS.size)
      end

      it 'does not fail if label is already existing' do
        label = Gitlab::BitbucketImport::Importer::LABELS.first
        ::Labels::CreateService.new(label).execute(project: project)

        expect { importer.execute }.not_to raise_error
      end

      it 'does not create new labels' do
        Gitlab::BitbucketImport::Importer::LABELS.each do |label|
          create(:label, project: project, title: label[:title])
        end

        expect { importer.execute }.not_to change { Label.count }
      end

      it 'does not update existing ones' do
        label_title = Gitlab::BitbucketImport::Importer::LABELS.first[:title]
        existing_label = create(:label, project: project, title: label_title)
        # Reload label from database so we avoid timestamp comparison issues related to time precision when comparing
        # attributes later.
        existing_label.reload

        Timecop.freeze(Time.now + 1.minute) do
          importer.execute

          label_after_import = project.labels.find(existing_label.id)
          expect(label_after_import.attributes).to eq(existing_label.attributes)
        end
      end
    end

    it 'maps statuses to open or closed' do
      allow(importer).to receive(:import_wiki)

      importer.execute

      expect(project.issues.where(state_id: Issue.available_states[:closed]).size).to eq(5)
      expect(project.issues.where(state_id: Issue.available_states[:opened]).size).to eq(2)
    end

    describe 'wiki import' do
      it 'is skipped when the wiki exists' do
        expect(project.wiki).to receive(:repository_exists?) { true }
        expect(importer.gitlab_shell).not_to receive(:import_wiki_repository)

        importer.execute

        expect(importer.errors).to be_empty
      end

      it 'imports to the project disk_path' do
        expect(project.wiki).to receive(:repository_exists?) { false }
        expect(importer.gitlab_shell).to receive(:import_wiki_repository)

        importer.execute

        expect(importer.errors).to be_empty
      end
    end

    describe 'issue import' do
      it 'maps reporters to anonymous if bitbucket reporter is nil' do
        allow(importer).to receive(:import_wiki)
        importer.execute

        expect(project.issues.size).to eq(7)
        expect(project.issues.where("description LIKE ?", '%Anonymous%').size).to eq(3)
        expect(project.issues.where("description LIKE ?", '%reporter1%').size).to eq(2)
        expect(project.issues.where("description LIKE ?", '%reporter2%').size).to eq(1)
        expect(project.issues.where("description LIKE ?", '%reporter3%').size).to eq(1)
        expect(importer.errors).to be_empty
      end
    end
  end
end
