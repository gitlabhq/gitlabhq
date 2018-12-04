# frozen_string_literal: true

require 'spec_helper'

describe BlobLanguageFromGitAttributes do
  include FakeBlobHelpers

  let(:project) { build(:project, :repository) }

  describe '#language_from_gitattributes' do
    subject(:blob) { fake_blob(path: 'file.md') }

    it 'returns return value from gitattribute' do
      expect(blob.project.repository).to receive(:gitattribute).with(blob.path, 'gitlab-language').and_return('erb?parent=json')

      expect(blob.language_from_gitattributes).to eq('erb?parent=json')
    end

    it 'returns nil if project is absent' do
      allow(blob).to receive(:project).and_return(nil)

      expect(blob.language_from_gitattributes).to eq(nil)
    end
  end
end
