# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::Readme do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository, :wiki_repo) }
  let(:blob) { fake_blob(path: 'README.md') }

  subject { described_class.new(blob) }

  describe '#render_error' do
    context 'when there is no wiki' do
      it 'returns :no_wiki' do
        expect(subject.render_error).to eq(:no_wiki)
      end
    end

    context 'when there is an external wiki' do
      before do
        project.has_external_wiki = true
      end

      it 'returns nil' do
        expect(subject.render_error).to be_nil
      end
    end

    context 'when there is a local wiki' do
      before do
        project.wiki_enabled = true
      end

      context 'when the wiki is empty' do
        it 'returns :no_wiki' do
          expect(subject.render_error).to eq(:no_wiki)
        end
      end

      context 'when the wiki is not empty' do
        before do
          create(:wiki_page, wiki: project.wiki, title: 'home', content: 'Home page')
        end

        it 'returns nil' do
          expect(subject.render_error).to be_nil
        end
      end
    end
  end
end
