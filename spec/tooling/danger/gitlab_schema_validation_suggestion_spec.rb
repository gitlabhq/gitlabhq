# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/gitlab_schema_validation_suggestion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::GitlabSchemaValidationSuggestion, feature_category: :cell do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:filename) { 'db/docs/application_settings.yml' }
  let(:file_lines) do
    file_diff.map { |line| line.delete_prefix('+') }
  end

  let(:file_diff) do
    [
      "+---",
      "+table_name: application_settings",
      "+classes:",
      "+- ApplicationSetting",
      "+feature_categories:",
      "+- continuous_integration",
      "+description: GitLab application settings",
      "+introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/commit/8589b4e137f50293952923bb07e2814257d7784d",
      "+milestone: '7.7'",
      "+gitlab_schema: #{schema}"
    ]
  end

  subject(:gitlab_schema_validation) { fake_danger.new(helper: fake_helper) }

  before do
    allow(gitlab_schema_validation).to receive(:project_helper).and_return(fake_project_helper)
    allow(gitlab_schema_validation.project_helper).to receive(:file_lines).and_return(file_lines)
    allow(gitlab_schema_validation.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    allow(gitlab_schema_validation.helper).to receive(:all_changed_files).and_return([filename])
  end

  shared_examples_for 'does not add a comment' do
    it do
      expect(gitlab_schema_validation).not_to receive(:markdown)

      gitlab_schema_validation.add_suggestions_on_using_clusterwide_schema
    end
  end

  context 'for discouraging the use of gitlab_main_clusterwide schema' do
    let(:schema) { 'gitlab_main_clusterwide' }

    context 'when the file path matches' do
      it 'adds the comment' do
        expected_comment = "\n#{described_class::SUGGESTION.chomp}"

        expect(gitlab_schema_validation).to receive(:markdown).with(expected_comment, file: filename, line: 10)

        gitlab_schema_validation.add_suggestions_on_using_clusterwide_schema
      end
    end

    context 'when the file path does not match' do
      let(:filename) { 'some_path/application_settings.yml' }

      it_behaves_like 'does not add a comment'
    end

    context 'for EE' do
      let(:filename) { 'ee/db/docs/application_settings.yml' }

      it_behaves_like 'does not add a comment'
    end

    context 'for a deleted table' do
      let(:filename) { 'db/docs/deleted_tables/application_settings.yml' }

      it_behaves_like 'does not add a comment'
    end
  end

  context 'on removing the gitlab_main_clusterwide schema' do
    let(:file_diff) do
      [
        "+---",
        "+table_name: application_settings",
        "+classes:",
        "+- ApplicationSetting",
        "+feature_categories:",
        "+- continuous_integration",
        "+description: GitLab application settings",
        "+introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/commit/8589b4e137f50293952923bb07e2814257d7784d",
        "+milestone: '7.7'",
        "-gitlab_schema: gitlab_main_clusterwide",
        "+gitlab_schema: gitlab_main_cell"
      ]
    end

    it_behaves_like 'does not add a comment'
  end

  context 'when a different schema is added' do
    let(:schema) { 'gitlab_main' }

    it_behaves_like 'does not add a comment'
  end
end
