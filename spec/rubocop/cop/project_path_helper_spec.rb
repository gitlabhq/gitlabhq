# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/project_path_helper'

RSpec.describe RuboCop::Cop::ProjectPathHelper do
  context "when using namespace_project with the project's namespace" do
    let(:source) { 'edit_namespace_project_issue_path(@issue.project.namespace, @issue.project, @issue)' }
    let(:correct_source) { 'edit_project_issue_path(@issue.project, @issue)' }

    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(<<~CODE)
        #{source}
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use short project path helpers without explicitly passing the namespace[...]
      CODE

      expect_correction(<<~CODE)
        #{correct_source}
      CODE
    end
  end

  context 'when using namespace_project with a different namespace' do
    it 'registers no offense' do
      expect_no_offenses('edit_namespace_project_issue_path(namespace, project)')
    end
  end
end
