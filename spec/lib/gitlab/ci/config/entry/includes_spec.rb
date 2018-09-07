require 'rails_helper'

describe Gitlab::Ci::Config::Entry::Includes do
  let(:entry) { described_class.new(config) }

  shared_examples 'valid external file' do
    it 'should be valid' do
      expect(entry).to be_valid
    end

    it 'should not return any error' do
      expect(entry.errors).to be_empty
    end
  end

  shared_examples 'invalid external file' do
    it 'should not be valid' do
      expect(entry).not_to be_valid
    end

    it 'should return an error' do
      expect(entry.errors.first).to match(/should be a valid local or remote file/)
    end
  end

  describe "#valid?" do
    context 'with no external file given' do
      let(:config) { nil }

      it_behaves_like 'valid external file'
    end

    context 'with multiple external files' do
      let(:config) { %w(https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-2.yml) }

      it_behaves_like 'valid external file'
    end

    context 'with just one external file' do
      let(:config) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' } 

      it_behaves_like 'valid external file'
    end

    context 'when they contain valid URLs' do
      let(:config) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' } 

      it_behaves_like 'valid external file'
    end

    context 'when they contain valid relative URLs' do
      let(:config) { '/vendor/gitlab-ci-yml/Auto-DevOps.gitlab-ci.yml' } 

      it_behaves_like 'valid external file'
    end

    context 'when they not contain valid URLs' do
      let(:config) { 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      it_behaves_like 'invalid external file'
    end

    context 'when they not contain valid relative URLs' do
      let(:config) { '/vendor/gitlab-ci-yml/non-existent-file.yml' }

      it_behaves_like 'invalid external file' 
    end
  end

  describe "#value" do
    context 'with multiple external files' do
      let(:config) { %w(https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-2.yml) }
      it 'should return an array' do
        expect(entry.value).to be_an(Array)
        expect(entry.value.count).to eq(2)
      end
    end

    context 'with just one external file' do
      let(:config) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      it 'should return an array' do
        expect(entry.value).to be_an(Array)
        expect(entry.value.count).to eq(1)
      end
    end

    context 'with no external file given' do
      let(:config) { nil }

      it 'should return an empty array' do
        expect(entry.value).to be_an(Array)
        expect(entry.value).to be_empty
      end
    end
  end
end
