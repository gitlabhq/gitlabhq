# frozen_string_literal: true

require 'spec_helper'

describe ExternalIssue do
  let(:project) { double('project', id: 1, to_reference: 'namespace1/project1') }
  let(:issue)   { described_class.new('EXT-1234', project) }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(issue.to_reference).to eq issue.id
    end
  end

  describe '#title' do
    it 'returns a title' do
      expect(issue.title).to eq "External Issue #{issue}"
    end
  end

  describe '#reference_link_text' do
    context 'if issue id has a prefix' do
      it 'returns the issue ID' do
        expect(issue.reference_link_text).to eq 'EXT-1234'
      end
    end

    context 'if issue id is a number' do
      let(:issue) { described_class.new('1234', project) }

      it 'returns the issue ID prefixed by #' do
        expect(issue.reference_link_text).to eq '#1234'
      end
    end
  end

  describe '#project_id' do
    it 'returns the ID of the project' do
      expect(issue.project_id).to eq(project.id)
    end
  end

  describe '#hash' do
    it 'returns the hash of its [class, to_s] pair' do
      issue_2 = described_class.new(issue.to_s, project)

      expect(issue.hash).to eq(issue_2.hash)
    end
  end
end
