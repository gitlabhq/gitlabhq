# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportSources, feature_category: :importers do
  describe '.values' do
    it 'returns an array' do
      expected =
        %w[
          github
          bitbucket
          bitbucket_server
          fogbugz
          git
          gitlab_project
          gitea
          manifest
          gitlab_built_in_project_template
        ]

      expect(described_class.values).to eq(expected)
    end
  end

  describe '.has_importer?' do
    it 'returns true when has import source has importer' do
      with_importer =
        %w[
          github
          bitbucket
          bitbucket_server
          fogbugz
          gitlab_project
          gitea
          gitlab_built_in_project_template
        ]

      without_importer = %w[git manifest doesnotexist]

      with_importer.each do |import_source|
        expect(described_class.has_importer?(import_source)).to be(true)
      end

      without_importer.each do |import_source|
        expect(described_class.has_importer?(import_source)).to be(false)
      end
    end
  end

  describe '.importer' do
    import_sources = {
      'github' => Gitlab::GithubImport::ParallelImporter,
      'bitbucket' => Gitlab::BitbucketImport::ParallelImporter,
      'bitbucket_server' => Gitlab::BitbucketServerImport::ParallelImporter,
      'fogbugz' => Gitlab::FogbugzImport::Importer,
      'git' => nil,
      'gitlab_project' => Gitlab::ImportExport::Importer,
      'gitea' => Gitlab::LegacyGithubImport::Importer,
      'manifest' => nil,
      'gitlab_built_in_project_template' => Gitlab::ImportExport::Importer,
      'doesnotexist' => nil,
      nil => nil
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
      'bitbucket' => 'Bitbucket Cloud',
      'bitbucket_server' => 'Bitbucket Server',
      'fogbugz' => 'FogBugz',
      'git' => 'Repository by URL',
      'gitlab_project' => 'GitLab export',
      'gitea' => 'Gitea',
      'manifest' => 'Manifest file',
      'gitlab_built_in_project_template' => 'GitLab built-in project template',
      'doesnotexist' => nil,
      nil => nil
    }

    import_sources.each do |name, title|
      it "returns #{title} when given #{name}" do
        expect(described_class.title(name)).to eq(title)
      end
    end
  end

  describe 'imports_repository? checker' do
    let(:allowed_importers) { %w[github gitlab_project bitbucket bitbucket_server gitlab_built_in_project_template] }

    it 'fails if any importer other than the allowed ones implements this method' do
      current_importers = described_class.values.select { |kind| described_class.importer(kind).try(:imports_repository?) }
      not_allowed_importers = current_importers - allowed_importers

      expect(not_allowed_importers).to be_empty, failure_message(not_allowed_importers)
    end

    def failure_message(importers_class_names)
      <<-MSG
        It looks like the #{importers_class_names.join(', ')} importers implements its own way to import the repository.
        That means that the lfs object download must be handled for each of them. You can use 'LfsImportService' and
        'LfsDownloadService' to implement it. After that, add the importer name to the list of allowed importers in this spec.
      MSG
    end
  end

  describe '.import_source' do
    subject { described_class.import_source(source) }

    context 'when import source exists' do
      let(:source) { 'github' }

      it { is_expected.to have_attributes(name: 'github') }
    end

    context 'when import source does not exist' do
      let(:source) { 'doesnotexist' }

      it { is_expected.to be_nil }
    end
  end

  describe '.template?' do
    subject { described_class.template?(template) }

    context 'when importer is project template importer' do
      let(:template) { 'gitlab_built_in_project_template' }

      it { is_expected.to be_truthy }
    end

    context 'when importer is not project template importer' do
      let(:template) { 'github' }

      it { is_expected.to be_falsey }
    end

    context 'when template is nil' do
      let(:template) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when template does not exist' do
      let(:template) { 'doesnotexist' }

      it { is_expected.to be_falsey }
    end
  end

  describe '.project_template_importers' do
    it 'returns names of project template importers' do
      expect(described_class.project_template_importers).to include('gitlab_built_in_project_template')
      expect(described_class.project_template_importers).not_to include('github')
    end
  end

  describe 'gitlab_built_in_project_template' do
    subject(:importer) { described_class.import_source('gitlab_built_in_project_template') }

    it 'uses Gitlab::ImportExport::Importer' do
      expect(importer.importer).to eq(Gitlab::ImportExport::Importer)
    end
  end
end
