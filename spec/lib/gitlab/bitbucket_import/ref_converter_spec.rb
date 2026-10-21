# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::RefConverter, feature_category: :importers do
  let_it_be(:project_identifier) { 'namespace/repo' }
  let_it_be(:project) { create(:project, import_source: project_identifier) }
  let(:path) { project.full_path }

  let(:ref_converter) { described_class.new(project) }

  shared_examples 'converts the ref correctly' do
    it 'converts the ref to a gitlab reference' do
      actual = ref_converter.convert_note(note)

      expect(actual).to eq(expected)
    end
  end

  context 'when the note has an issue ref' do
    let(:note) { "[https://bitbucket.org/namespace/repo/issues/1/first-issue](https://bitbucket.org/namespace/repo/issues/1/first-issue){: data-inline-card='' } " }
    let(:expected) { "[https://bitbucket.org/namespace/repo/issues/1/first-issue](https://bitbucket.org/namespace/repo/issues/1/first-issue)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note references issues without an issue name' do
    let(:note) { "[https://bitbucket.org/namespace/repo/issues](https://bitbucket.org/namespace/repo/issues){: data-inline-card='' } " }
    let(:expected) { "[https://bitbucket.org/namespace/repo/issues](https://bitbucket.org/namespace/repo/issues)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note has both an issue ref and a pull request ref' do
    let(:note) { "See https://bitbucket.org/namespace/repo/issues/1/first-issue and https://bitbucket.org/namespace/repo/pull-requests/7" }
    let(:expected) { "See https://bitbucket.org/namespace/repo/issues/1/first-issue and http://localhost/#{path}/-/merge_requests/7" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note has a pull request ref' do
    let(:note) { "[https://bitbucket.org/namespace/repo/pull-requests/7](https://bitbucket.org/namespace/repo/pull-requests/7){: data-inline-card='' } " }
    let(:expected) { "[http://localhost/#{path}/-/merge_requests/7](http://localhost/#{path}/-/merge_requests/7)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note has a reference to a branch' do
    let(:note) { "[https://bitbucket.org/namespace/repo/src/master/](https://bitbucket.org/namespace/repo/src/master/){: data-inline-card='' } " }
    let(:expected) { "[http://localhost/#{path}/-/blob/master/](http://localhost/#{path}/-/blob/master/)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note has a reference to a line in a file' do
    let(:note) do
      "[https://bitbucket.org/namespace/repo/src/0f16a22c21671421780980c9a7433eb8c986b9af/.gitignore#lines-6] \
      (https://bitbucket.org/namespace/repo/src/0f16a22c21671421780980c9a7433eb8c986b9af/.gitignore#lines-6) \
      {: data-inline-card='' }"
    end

    let(:expected) do
      "[http://localhost/#{path}/-/blob/0f16a22c21671421780980c9a7433eb8c986b9af/.gitignore#L6] \
      (http://localhost/#{path}/-/blob/0f16a22c21671421780980c9a7433eb8c986b9af/.gitignore#L6)"
    end

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note has a reference to a file' do
    let(:note) { "[https://bitbucket.org/namespace/repo/src/master/.gitignore](https://bitbucket.org/namespace/repo/src/master/.gitignore){: data-inline-card='' } " }
    let(:expected) { "[http://localhost/#{path}/-/blob/master/.gitignore](http://localhost/#{path}/-/blob/master/.gitignore)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note links to a repository whose name starts with the imported one' do
    let(:note) { 'https://bitbucket.org/namespace/repo-two/pull-requests/7' }
    let(:expected) { note }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the repository URL ends a sentence' do
    let(:note) { 'See https://bitbucket.org/namespace/repo. It has the details.' }
    let(:expected) { "See http://localhost/#{path}. It has the details." }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the repository URL is followed by an ellipsis' do
    let(:note) { 'See https://bitbucket.org/namespace/repo...' }
    let(:expected) { "See http://localhost/#{path}..." }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the repository URL is followed by a long run of dots' do
    let(:note) { "See https://bitbucket.org/namespace/repo#{'.' * 10_000} for details" }
    let(:expected) { "See http://localhost/#{path}#{'.' * 10_000} for details" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note links to a repository whose slug continues after a dot' do
    where(:url) do
      %w[
        https://bitbucket.org/namespace/repo.git
        https://bitbucket.org/namespace/repo.name/pull-requests/7
        https://bitbucket.org/namespace/repo.-two
        https://bitbucket.org/namespace/repo..two
        https://bitbucket.org/namespace/repo_two
        https://bitbucket.org/namespace/repo2
      ]
    end

    with_them do
      let(:note) { "See #{url}" }
      let(:expected) { note }

      it_behaves_like 'converts the ref correctly'
    end
  end

  context 'when the GitLab project URL contains a converted path segment' do
    let_it_be(:project) { create(:project, path: 'my-src-project', import_source: project_identifier) }

    let(:note) { 'https://bitbucket.org/namespace/repo/src/master/.gitignore' }
    let(:expected) { "http://localhost/#{path}/-/blob/master/.gitignore" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note does not have a ref' do
    let(:note) { 'Hello world' }
    let(:expected) { 'Hello world' }

    it_behaves_like 'converts the ref correctly'
  end
end
