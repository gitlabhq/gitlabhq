require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/project_path_helper'

describe RuboCop::Cop::ProjectPathHelper do
  include CopHelper

  subject(:cop) { described_class.new }

  context "when using namespace_project with the project's namespace" do
    let(:source) { 'edit_namespace_project_issue_path(@issue.project.namespace, @issue.project, @issue)' }
    let(:correct_source) { 'edit_project_issue_path(@issue.project, @issue)' }

    it 'registers an offense' do
      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq(['edit_namespace_project_issue_path'])
      end
    end

    it 'autocorrects to the right version' do
      autocorrected = autocorrect_source(source)

      expect(autocorrected).to eq(correct_source)
    end
  end

  context 'when using namespace_project with a different namespace' do
    it 'registers no offense' do
      inspect_source('edit_namespace_project_issue_path(namespace, project)')

      expect(cop.offenses.size).to eq(0)
    end
  end
end
