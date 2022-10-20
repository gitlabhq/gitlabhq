# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::SingleEndpointIssueNotesImporter do
  let(:client) { double }
  let(:project) { create(:project, import_source: 'github/repo') }

  subject { described_class.new(project, client) }

  it { is_expected.to include_module(Gitlab::GithubImport::ParallelScheduling) }
  it { is_expected.to include_module(Gitlab::GithubImport::SingleEndpointNotesImporting) }
  it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::Note) }
  it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::NoteImporter) }
  it { expect(subject.collection_method).to eq(:issue_comments) }
  it { expect(subject.object_type).to eq(:note) }
  it { expect(subject.id_for_already_imported_cache({ id: 1 })).to eq(1) }

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let(:issue) do
      create(
        :issue,
        iid: 999,
        project: project
      )
    end

    let(:note) { { id: 1 } }
    let(:page) { double(objects: [note], number: 1) }

    it 'fetches data' do
      expect(client)
        .to receive(:each_page)
        .exactly(:once) # ensure to be cached on the second call
        .with(:issue_comments, 'github/repo', issue.iid, { page: 1 })
        .and_yield(page)

      expect { |b| subject.each_object_to_import(&b) }.to yield_with_args(note)

      subject.each_object_to_import {}

      expect(
        Gitlab::Cache::Import::Caching.set_includes?(
          "github-importer/issue/notes/already-imported/#{project.id}",
          issue.iid
        )
      ).to eq(true)
    end

    it 'skips cached pages' do
      Gitlab::GithubImport::PageCounter
        .new(project, "issue/#{issue.id}/issue_comments")
        .set(2)

      expect(client)
        .to receive(:each_page)
        .exactly(:once) # ensure to be cached on the second call
        .with(:issue_comments, 'github/repo', issue.iid, { page: 2 })

      subject.each_object_to_import {}
    end

    it 'skips cached merge requests' do
      Gitlab::Cache::Import::Caching.set_add(
        "github-importer/issue/notes/already-imported/#{project.id}",
        issue.iid
      )

      expect(client).not_to receive(:each_page)

      subject.each_object_to_import {}
    end
  end
end
