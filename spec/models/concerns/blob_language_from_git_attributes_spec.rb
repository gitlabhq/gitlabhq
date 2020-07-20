# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobLanguageFromGitAttributes do
  include FakeBlobHelpers

  let(:project) { build(:project, :repository) }

  describe '#language_from_gitattributes' do
    subject(:blob) { fake_blob(path: 'file.md') }

    it 'returns return value from gitattribute' do
      allow(blob.repository).to receive(:exists?).and_return(true)
      expect(blob.repository).to receive(:gitattribute).with(blob.path, 'gitlab-language').and_return('erb?parent=json')

      expect(blob.language_from_gitattributes).to eq('erb?parent=json')
    end

    it 'returns nil if repository is absent' do
      allow(blob).to receive(:repository).and_return(nil)

      expect(blob.language_from_gitattributes).to eq(nil)
    end

    it 'returns nil if repository does not exist' do
      allow(blob.repository).to receive(:exists?).and_return(false)

      expect(blob.language_from_gitattributes).to eq(nil)
    end
  end
end
