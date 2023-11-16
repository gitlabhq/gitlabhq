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
    let(:expected) { "[http://localhost/#{path}/-/issues/1](http://localhost/#{path}/-/issues/1)" }

    it_behaves_like 'converts the ref correctly'
  end

  context 'when the note references issues without an issue name' do
    let(:note) { "[https://bitbucket.org/namespace/repo/issues](https://bitbucket.org/namespace/repo/issues){: data-inline-card='' } " }
    let(:expected) { "[http://localhost/#{path}/-/issues](http://localhost/#{path}/-/issues)" }

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

  context 'when the note does not have a ref' do
    let(:note) { 'Hello world' }
    let(:expected) { 'Hello world' }

    it_behaves_like 'converts the ref correctly'
  end
end
