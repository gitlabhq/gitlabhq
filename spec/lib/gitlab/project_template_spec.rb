# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ProjectTemplate do
  describe '.all' do
    it 'returns a all templates' do
      expected = [
        described_class.new('rails', 'Ruby on Rails', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/rails'),
        described_class.new('spring', 'Spring', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/spring'),
        described_class.new('express', 'NodeJS Express', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/express'),
        described_class.new('iosswift', 'iOS (Swift)', 'A ready-to-go template for use with iOS Swift apps.', 'https://gitlab.com/gitlab-org/project-templates/iosswift'),
        described_class.new('dotnetcore', '.NET Core', 'A .NET Core console application template, customizable for any .NET Core project', 'https://gitlab.com/gitlab-org/project-templates/dotnetcore'),
        described_class.new('android', 'Android', 'A ready-to-go template for use with Android apps.', 'https://gitlab.com/gitlab-org/project-templates/android'),
        described_class.new('gomicro', 'Go Micro', 'Go Micro is a framework for micro service development.', 'https://gitlab.com/gitlab-org/project-templates/go-micro'),
        described_class.new('hugo', 'Pages/Hugo', 'Everything you need to get started using a Hugo Pages site.', 'https://gitlab.com/pages/hugo'),
        described_class.new('jekyll', 'Pages/Jekyll', 'Everything you need to get started using a Jekyll Pages site.', 'https://gitlab.com/pages/jekyll'),
        described_class.new('plainhtml', 'Pages/Plain HTML', 'Everything you need to get started using a plain HTML Pages site.', 'https://gitlab.com/pages/plain-html'),
        described_class.new('gitbook', 'Pages/GitBook', 'Everything you need to get started using a GitBook Pages site.', 'https://gitlab.com/pages/gitbook'),
        described_class.new('hexo', 'Pages/Hexo', 'Everything you need to get started using a Hexo Pages site.', 'https://gitlab.com/pages/hexo'),
        described_class.new('nfhugo', 'Netlify/Hugo', _('A Hugo site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfhugo'),
        described_class.new('nfjekyll', 'Netlify/Jekyll', _('A Jekyll site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfjekyll'),
        described_class.new('nfplainhtml', 'Netlify/Plain HTML', _('A plain HTML site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfplain-html'),
        described_class.new('nfgitbook', 'Netlify/GitBook', _('A GitBook site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfgitbook'),
        described_class.new('nfhexo', 'Netlify/Hexo', _('A Hexo site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfhexo'),
        described_class.new('salesforcedx', 'SalesforceDX', _('A project boilerplate for Salesforce App development with Salesforce Developer tools.'), 'https://gitlab.com/gitlab-org/project-templates/salesforcedx'),
        described_class.new('serverless_framework', 'Serverless Framework/JS', _('A basic page and serverless function that uses AWS Lambda, AWS API Gateway, and GitLab Pages'), 'https://gitlab.com/gitlab-org/project-templates/serverless-framework', 'illustrations/logos/serverless_framework.svg')
      ]

      expect(described_class.all).to be_an(Array)
      expect(described_class.all).to eq(expected)
    end
  end

  describe '#project_path' do
    subject { described_class.new('name', 'title', 'description', 'https://gitlab.com/some/project/path').project_path }

    it { is_expected.to eq 'some/project/path' }
  end

  describe '#uri_encoded_project_path' do
    subject { described_class.new('name', 'title', 'description', 'https://gitlab.com/some/project/path').uri_encoded_project_path }

    it { is_expected.to eq 'some%2Fproject%2Fpath' }
  end

  describe '.find' do
    subject { described_class.find(query) }

    context 'when there is a match' do
      let(:query) { :rails }

      it { is_expected.to be_a(described_class) }
    end

    context 'when there is no match' do
      let(:query) { 'no-match' }

      it { is_expected.to be(nil) }
    end
  end

  describe '.archive_directory' do
    subject { described_class.archive_directory }

    it { is_expected.to be_a Pathname }
  end

  describe 'instance methods' do
    subject { described_class.new('phoenix', 'Phoenix Framework', 'Phoenix description', 'link-to-template') }

    it { is_expected.to respond_to(:logo, :file, :archive_path) }
  end

  describe 'validate all templates' do
    set(:admin) { create(:admin) }

    described_class.all.each do |template|
      it "#{template.name} has a valid archive" do
        archive = template.archive_path

        expect(File.exist?(archive)).to be(true)
      end

      context 'with valid parameters' do
        it 'can be imported' do
          params = {
            template_name: template.name,
            namespace_id: admin.namespace.id,
            path: template.name
          }

          project = Projects::CreateFromTemplateService.new(admin, params).execute

          expect(project).to be_valid
          expect(project).to be_persisted
        end
      end
    end
  end
end
