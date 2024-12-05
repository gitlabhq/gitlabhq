# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::FoundBlob, feature_category: :global_search do
  let(:project) { create(:project, :public, :repository) }

  describe 'parsing content results' do
    let(:results) { project.repository.search_files_by_content('feature', 'master') }
    let(:search_result) { results.first }

    subject { described_class.new(content_match: search_result, project: project) }

    it 'returns a valid FoundBlob' do
      is_expected.to be_an described_class
      expect(subject.id).to be_nil
      expect(subject.path).to eq('CHANGELOG')
      expect(subject.basename).to eq('CHANGELOG')
      expect(subject.ref).to eq('master')
      expect(subject.startline).to eq(188)
      expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n")
    end

    it 'does not parse content if not needed' do
      expect(subject).not_to receive(:parse_search_result)
      expect(subject.project_id).to eq(project.id)
      expect(subject.binary_path).to eq('CHANGELOG')
    end

    it 'parses content only once when needed' do
      expect(subject).to receive(:parse_search_result).once.and_call_original
      expect(subject.path).to eq('CHANGELOG')
      expect(subject.startline).to eq(188)
    end

    context 'when the matching filename contains a colon' do
      let(:search_result) { "master:testdata/project::function1.yaml\x001\x00---\n" }

      it 'returns a valid FoundBlob' do
        expect(subject.path).to eq('testdata/project::function1.yaml')
        expect(subject.basename).to eq('testdata/project::function1')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(1)
        expect(subject.data).to eq("---\n")
      end
    end

    context 'when the matching content contains a number surrounded by colons' do
      let(:search_result) { "master:testdata/foo.txt\x001\x00blah:9:blah" }

      it 'returns a valid FoundBlob' do
        expect(subject.path).to eq('testdata/foo.txt')
        expect(subject.basename).to eq('testdata/foo')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(1)
        expect(subject.data).to eq('blah:9:blah')
      end
    end

    context 'when the matching content contains multiple null bytes' do
      let(:search_result) { "master:testdata/foo.txt\x001\x00blah\x001\x00foo" }

      it 'returns a valid FoundBlob' do
        expect(subject.path).to eq('testdata/foo.txt')
        expect(subject.basename).to eq('testdata/foo')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(1)
        expect(subject.data).to eq("blah\x001\x00foo")
      end
    end

    context 'when the search result ends with an empty line' do
      let(:results) { project.repository.search_files_by_content('Role models', 'master') }

      it 'returns a valid FoundBlob that ends with an empty line' do
        expect(subject.path).to eq('files/markdown/ruby-style-guide.md')
        expect(subject.basename).to eq('files/markdown/ruby-style-guide')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(1)
        expect(subject.data).to eq("# Prelude\n\n> Role models are important. <br/>\n> -- Officer Alex J. Murphy / RoboCop\n\n")
      end
    end

    context 'when the search returns non-ASCII data' do
      context 'with UTF-8' do
        let(:results) { project.repository.search_files_by_content('файл', 'master') }

        it 'returns results as UTF-8' do
          expect(subject.path).to eq('encoding/russian.rb')
          expect(subject.basename).to eq('encoding/russian')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(1)
          expect(subject.data).to eq("Хороший файл\n")
        end
      end

      context 'with UTF-8 in the filename' do
        let(:results) { project.repository.search_files_by_content('webhook', 'master') }

        it 'returns results as UTF-8' do
          expect(subject.path).to eq('encoding/テスト.txt')
          expect(subject.basename).to eq('encoding/テスト')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(3)
          expect(subject.data).to include('WebHookの確認')
        end
      end

      context 'with ISO-8859-1' do
        let(:search_result) { (+"master:encoding/iso8859.txt\x001\x00\xC4\xFC\nmaster:encoding/iso8859.txt\x002\x00\nmaster:encoding/iso8859.txt\x003\x00foo\n").force_encoding(Encoding::ASCII_8BIT) }

        it 'returns results as UTF-8' do
          expect(subject.path).to eq('encoding/iso8859.txt')
          expect(subject.basename).to eq('encoding/iso8859')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(1)
          expect(subject.data).to eq("Äü\n\nfoo\n")
        end
      end
    end

    context 'when filename has extension' do
      let(:search_result) { "master:CONTRIBUTE.md\x005\x00- [Contribute to GitLab](#contribute-to-gitlab)\n" }

      it { expect(subject.path).to eq('CONTRIBUTE.md') }
      it { expect(subject.basename).to eq('CONTRIBUTE') }
    end

    context 'when file is under directory' do
      let(:search_result) { "master:a/b/c.md\x005\x00a b c\n" }

      it { expect(subject.path).to eq('a/b/c.md') }
      it { expect(subject.basename).to eq('a/b/c') }
    end
  end

  describe 'parsing title results' do
    context 'when file is under directory' do
      let(:path) { 'a/b/c.md' }

      subject { described_class.new(blob_path: path, project: project, ref: 'master') }

      before do
        allow(Gitlab::Git::Blob)
          .to receive(:batch).and_return([Gitlab::Git::Blob.new(path: path)])
      end

      it { expect(subject.path).to eq('a/b/c.md') }
      it { expect(subject.basename).to eq('a/b/c') }

      context 'when filename has multiple extensions' do
        let(:path) { 'a/b/c.whatever.md' }

        it { expect(subject.basename).to eq('a/b/c.whatever') }
      end
    end
  end

  describe 'policy' do
    let(:project) { build(:project, :repository) }

    subject { described_class.new(project: project) }

    it 'works with policy' do
      expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_truthy
    end
  end
end
