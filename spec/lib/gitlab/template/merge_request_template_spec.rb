# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::MergeRequestTemplate do
  let(:project) { create(:project, :repository, create_templates: :merge_request) }

  describe '.all' do
    it 'strips the md suffix' do
      expect(described_class.all(project).first.name).not_to end_with('.issue_template')
    end

    it 'combines the globals and rest' do
      all = described_class.all(project).map(&:name)

      expect(all).to include('bug')
      expect(all).to include('feature_proposal')
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect { described_class.find('mepmep-yadida', project) }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
    end

    it 'returns the merge request object of a valid file' do
      ruby = described_class.find('bug', project)

      expect(ruby).to be_a described_class
      expect(ruby.name).to eq('bug')
    end
  end

  describe '.by_category' do
    it 'return array of templates' do
      all = described_class.by_category('', project).map(&:name)
      expect(all).to include('bug')
      expect(all).to include('feature_proposal')
    end

    context 'when repo is bare or empty' do
      let(:empty_project) { create(:project) }

      it "returns empty array" do
        templates = described_class.by_category('', empty_project)

        expect(templates).to be_empty
      end
    end
  end

  describe '#content' do
    it 'loads the full file' do
      issue_template = described_class.new('.gitlab/merge_request_templates/bug.md', project)

      expect(issue_template.name).to eq 'bug'
      expect(issue_template.content).to eq('something valid')
    end

    it 'raises error when file is not found' do
      issue_template = described_class.new('.gitlab/merge_request_templates/bugnot.md', project)
      expect { issue_template.content }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
    end

    context "when repo is empty" do
      let(:empty_project) { create(:project) }

      it "raises file not found" do
        issue_template = described_class.new('.gitlab/merge_request_templates/not_existent.md', empty_project)

        expect { issue_template.content }.to raise_error(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
      end
    end
  end
end
