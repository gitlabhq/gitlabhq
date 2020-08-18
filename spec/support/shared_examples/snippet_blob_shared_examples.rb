# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'snippet blob raw path' do
  let(:blob) { snippet.blobs.first }
  let(:ref)  { blob.repository.root_ref }

  context 'for PersonalSnippets' do
    let(:snippet) { personal_snippet }

    it 'returns the raw personal snippet blob path' do
      expect(subject).to eq("/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}")
    end
  end

  context 'for ProjectSnippets' do
    let(:snippet) { project_snippet }

    it 'returns the raw project snippet blob path' do
      expect(subject).to eq("/#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}")
    end
  end
end

RSpec.shared_examples 'snippet blob raw url' do
  let(:blob) { snippet.blobs.first }
  let(:ref)  { blob.repository.root_ref }

  context 'for PersonalSnippets' do
    let(:snippet) { personal_snippet }

    it 'returns the raw personal snippet blob url' do
      expect(subject).to eq("http://test.host/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}")
    end
  end

  context 'for ProjectSnippets' do
    let(:snippet) { project_snippet }

    it 'returns the raw project snippet blob url' do
      expect(subject).to eq("http://test.host/#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}")
    end
  end
end
