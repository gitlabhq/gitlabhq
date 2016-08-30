require 'spec_helper'

describe Gitlab::Template::IssueTemplate do
  subject { described_class }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:file_path_1) { '.gitlab/issue_templates/bug.md' }
  let(:file_path_2) { '.gitlab/issue_templates/template_test.md' }
  let(:file_path_3) { '.gitlab/issue_templates/feature_proposal.md' }

  before do
    project.team.add_user(user, Gitlab::Access::MASTER)
    project.repository.commit_file(user, file_path_1, "something valid", "test 3", "master", false)
    project.repository.commit_file(user, file_path_2, "template_test", "test 1", "master", false)
    project.repository.commit_file(user, file_path_3, "feature_proposal", "test 2", "master", false)
  end

  describe '.all' do
    it 'strips the md suffix' do
      expect(subject.all(project).first.name).not_to end_with('.issue_template')
    end

    it 'combines the globals and rest' do
      all = subject.all(project).map(&:name)

      expect(all).to include('bug')
      expect(all).to include('feature_proposal')
      expect(all).to include('template_test')
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect { subject.find('mepmep-yadida', project) }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
    end

    it 'returns the issue object of a valid file' do
      ruby = subject.find('bug', project)

      expect(ruby).to be_a Gitlab::Template::IssueTemplate
      expect(ruby.name).to eq('bug')
    end
  end

  describe '.by_category' do
    it 'return array of templates' do
      all = subject.by_category('', project).map(&:name)
      expect(all).to include('bug')
      expect(all).to include('feature_proposal')
      expect(all).to include('template_test')
    end

    context 'when repo is bare or empty' do
      let(:empty_project) { create(:empty_project) }
      before { empty_project.team.add_user(user, Gitlab::Access::MASTER) }

      it "returns empty array" do
        templates = subject.by_category('', empty_project)
        expect(templates).to be_empty
      end
    end
  end

  describe '#content' do
    it 'loads the full file' do
      issue_template = subject.new('.gitlab/issue_templates/bug.md', project)

      expect(issue_template.name).to eq 'bug'
      expect(issue_template.content).to eq('something valid')
    end

    it 'raises error when file is not found' do
      issue_template = subject.new('.gitlab/issue_templates/bugnot.md', project)
      expect { issue_template.content }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
    end

    context "when repo is empty" do
      let(:empty_project) { create(:empty_project) }

      before { empty_project.team.add_user(user, Gitlab::Access::MASTER) }

      it "raises file not found" do
        issue_template = subject.new('.gitlab/issue_templates/not_existent.md', empty_project)
        expect { issue_template.content }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
      end
    end
  end
end
