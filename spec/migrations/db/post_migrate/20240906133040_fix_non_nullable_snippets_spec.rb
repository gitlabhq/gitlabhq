# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixNonNullableSnippets, migration: :gitlab_main, feature_category: :source_code_management do
  let(:migration) { described_class.new }
  let(:snippets) { table(:snippets) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let!(:personal_snippet) do
    snippets.create!(
      type: 'PersonalSnippet', author_id: 1, project_id: nil, title: 'Snippet1', organization_id: 1
    )
  end

  let!(:project_snippet_with_organization) do
    snippets.create!(
      type: 'ProjectSnippet', author_id: 1, project_id: project.id, title: 'Snippet2', organization_id: 1
    )
  end

  let!(:project_snippet_without_organization) do
    snippets.create!(
      type: 'ProjectSnippet', author_id: 1, project_id: project.id, title: 'Snippet3', organization_id: nil
    )
  end

  describe '#up' do
    context 'when GitLab.com', :saas do
      it 'nullfies organization_id for project snippets' do
        expect { migrate! }
          .to change { project_snippet_with_organization.reload.organization_id }.from(1).to(nil)
          .and not_change { personal_snippet.reload.organization_id }.from(1)
          .and not_change { project_snippet_without_organization.reload.organization_id }.from(nil)
      end
    end

    context 'when self-managed' do
      it 'does not update organization_id for project snippets' do
        expect { migrate! }
          .to not_change { project_snippet_with_organization.reload.organization_id }.from(1)
          .and not_change { personal_snippet.reload.organization_id }.from(1)
          .and not_change { project_snippet_without_organization.reload.organization_id }.from(nil)
      end
    end
  end
end
