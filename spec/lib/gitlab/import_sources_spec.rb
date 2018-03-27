require 'spec_helper'

describe Gitlab::ImportSources do
  describe '.options' do
    it 'returns a hash' do
      expected =
        {
          'GitHub'        => 'github',
          'Bitbucket'     => 'bitbucket',
          'GitLab.com'    => 'gitlab',
          'Google Code'   => 'google_code',
          'FogBugz'       => 'fogbugz',
          'Repo by URL'   => 'git',
          'GitLab export' => 'gitlab_project',
          'Gitea'         => 'gitea'
        }

      expect(described_class.options).to eq(expected)
    end
  end

  describe '.values' do
    it 'returns an array' do
      expected =
        %w(
          github
          bitbucket
          gitlab
          google_code
          fogbugz
          git
          gitlab_project
          gitea
        )

      expect(described_class.values).to eq(expected)
    end
  end

  describe '.importer_names' do
    it 'returns an array of importer names' do
      expected =
        %w(
          github
          bitbucket
          gitlab
          google_code
          fogbugz
          gitlab_project
          gitea
        )

      expect(described_class.importer_names).to eq(expected)
    end
  end

  describe '.importer' do
    import_sources = {
      'github' => Gitlab::GithubImport::ParallelImporter,
      'bitbucket' => Gitlab::BitbucketImport::Importer,
      'gitlab' => Gitlab::GitlabImport::Importer,
      'google_code' => Gitlab::GoogleCodeImport::Importer,
      'fogbugz' => Gitlab::FogbugzImport::Importer,
      'git' => nil,
      'gitlab_project' => Gitlab::ImportExport::Importer,
      'gitea' => Gitlab::LegacyGithubImport::Importer
    }

    import_sources.each do |name, klass|
      it "returns #{klass} when given #{name}" do
        expect(described_class.importer(name)).to eq(klass)
      end
    end
  end

  describe '.title' do
    import_sources = {
      'github' => 'GitHub',
      'bitbucket' => 'Bitbucket',
      'gitlab' => 'GitLab.com',
      'google_code' => 'Google Code',
      'fogbugz' => 'FogBugz',
      'git' => 'Repo by URL',
      'gitlab_project' => 'GitLab export',
      'gitea' => 'Gitea'
    }

    import_sources.each do |name, title|
      it "returns #{title} when given #{name}" do
        expect(described_class.title(name)).to eq(title)
      end
    end
  end
end
