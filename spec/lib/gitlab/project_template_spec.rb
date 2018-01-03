require 'spec_helper'

describe Gitlab::ProjectTemplate do
  describe '.all' do
    it 'returns a all templates' do
      expected = [
        described_class.new('rails', 'Ruby on Rails', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/rails'),
        described_class.new('spring', 'Spring', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/spring'),
        described_class.new('express', 'NodeJS Express', 'Includes an MVC structure, .gitignore, Gemfile, and more great stuff', 'https://gitlab.com/gitlab-org/project-templates/express')
      ]

      expect(described_class.all).to be_an(Array)
      expect(described_class.all).to eq(expected)
    end
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
