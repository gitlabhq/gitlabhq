# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::WikiFormatter do
  let(:project) do
    create(:project,
      namespace: create(:namespace, path: 'gitlabhq'),
      import_url: 'https://xxx@github.com/gitlabhq/sample.gitlabhq.git')
  end

  subject(:wiki) { described_class.new(project) }

  describe '#disk_path' do
    it 'appends .wiki to disk path' do
      expect(wiki.disk_path).to eq project.wiki.disk_path
    end
  end

  describe '#full_path' do
    it 'appends .wiki to project path' do
      expect(wiki.full_path).to eq project.wiki.full_path
    end
  end

  describe '#import_url' do
    it 'returns URL of the wiki repository' do
      expect(wiki.import_url).to eq 'https://xxx@github.com/gitlabhq/sample.gitlabhq.wiki.git'
    end
  end
end
