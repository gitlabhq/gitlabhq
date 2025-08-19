# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::SnippetParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }

  let(:user) { create(:user) }
  let(:external_user) { create(:user, :external) }
  let(:project_member) { create(:user) }
  let(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  def visible_references(snippet_visibility, user = nil)
    snippet = create(:project_snippet, snippet_visibility, project: project)
    link['data-project'] = project.id.to_s
    link['data-snippet'] = snippet.id.to_s

    subject.nodes_visible_to_user(user, [link])
  end

  before do
    project.add_member(project_member, :developer)
  end

  describe '#nodes_visible_to_user' do
    context 'when a project is public and the snippets feature is enabled for everyone' do
      before do
        project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::ENABLED)
      end

      it 'avoids N+1 cached queries', :use_sql_query_cache do
        # Run this once to establish a baseline
        visible_references(:public)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          subject.nodes_visible_to_user(user, [link])
        end

        expect { subject.nodes_visible_to_user(user, Array.new(10, link)) }.not_to exceed_all_query_limit(control)
      end

      it 'creates a reference for guest for a public snippet' do
        expect(visible_references(:public)).to eq([link])
      end

      it 'creates a reference for a regular user for a public snippet' do
        expect(visible_references(:public, user)).to eq([link])
      end

      it 'creates a reference for a regular user for an internal snippet' do
        expect(visible_references(:internal, user)).to eq([link])
      end

      it 'does not create a reference for an external user for an internal snippet' do
        expect(visible_references(:internal, external_user)).to be_empty
      end

      it 'creates a reference for a project member for a private snippet' do
        expect(visible_references(:private, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for a private snippet' do
        expect(visible_references(:private, user)).to be_empty
      end
    end

    context 'when a project is public and the snippets feature is enabled for project team members' do
      before do
        project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::PRIVATE)
      end

      it 'creates a reference for a project member for a public snippet' do
        expect(visible_references(:public, project_member)).to eq([link])
      end

      it 'does not create a reference for guest for a public snippet' do
        expect(visible_references(:public, nil)).to be_empty
      end

      it 'does not create a reference for a regular user for a public snippet' do
        expect(visible_references(:public, user)).to be_empty
      end

      it 'creates a reference for a project member for an internal snippet' do
        expect(visible_references(:internal, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for an internal snippet' do
        expect(visible_references(:internal, user)).to be_empty
      end

      it 'creates a reference for a project member for a private snippet' do
        expect(visible_references(:private, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for a private snippet' do
        expect(visible_references(:private, user)).to be_empty
      end
    end

    context 'when a project is internal and the snippets feature is enabled for everyone' do
      before do
        project.update_attribute(:visibility, Gitlab::VisibilityLevel::INTERNAL)
        project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::ENABLED)
      end

      it 'does not create a reference for guest for a public snippet' do
        expect(visible_references(:public)).to be_empty
      end

      it 'does not create a reference for an external user for a public snippet' do
        expect(visible_references(:public, external_user)).to be_empty
      end

      it 'creates a reference for a regular user for a public snippet' do
        expect(visible_references(:public, user)).to eq([link])
      end

      it 'creates a reference for a regular user for an internal snippet' do
        expect(visible_references(:internal, user)).to eq([link])
      end

      it 'does not create a reference for an external user for an internal snippet' do
        expect(visible_references(:internal, external_user)).to be_empty
      end

      it 'creates a reference for a project member for a private snippet' do
        expect(visible_references(:private, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for a private snippet' do
        expect(visible_references(:private, user)).to be_empty
      end
    end

    context 'when a project is internal and the snippets feature is enabled for project team members' do
      before do
        project.update_attribute(:visibility, Gitlab::VisibilityLevel::INTERNAL)
        project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::PRIVATE)
      end

      it 'creates a reference for a project member for a public snippet' do
        expect(visible_references(:public, project_member)).to eq([link])
      end

      it 'does not create a reference for guest for a public snippet' do
        expect(visible_references(:public, nil)).to be_empty
      end

      it 'does not create reference for a regular user for a public snippet' do
        expect(visible_references(:public, user)).to be_empty
      end

      it 'creates a reference for a project member for an internal snippet' do
        expect(visible_references(:internal, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for an internal snippet' do
        expect(visible_references(:internal, user)).to be_empty
      end

      it 'creates a reference for a project member for a private snippet' do
        expect(visible_references(:private, project_member)).to eq([link])
      end

      it 'does not create reference for a regular user for a private snippet' do
        expect(visible_references(:private, user)).to be_empty
      end
    end

    context 'when a project is private and the snippets feature is enabled for project team members' do
      before do
        project.update_attribute(:visibility, Gitlab::VisibilityLevel::PRIVATE)
        project.project_feature.update_attribute(:snippets_access_level, ProjectFeature::PRIVATE)
      end

      it 'creates a reference for a project member for a public snippet' do
        expect(visible_references(:public, project_member)).to eq([link])
      end

      it 'does not create a reference for guest for a public snippet' do
        expect(visible_references(:public, nil)).to be_empty
      end

      it 'does not create a reference for a regular user for a public snippet' do
        expect(visible_references(:public, user)).to be_empty
      end

      it 'creates a reference for a project member for an internal snippet' do
        expect(visible_references(:internal, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for an internal snippet' do
        expect(visible_references(:internal, user)).to be_empty
      end

      it 'creates a reference for a project member for a private snippet' do
        expect(visible_references(:private, project_member)).to eq([link])
      end

      it 'does not create a reference for a regular user for a private snippet' do
        expect(visible_references(:private, user)).to be_empty
      end
    end
  end

  describe '#referenced_by' do
    let(:snippet) { create(:project_snippet, project: project) }

    describe 'when the link has a data-snippet attribute' do
      context 'using an existing snippet ID' do
        it 'returns an Array of snippets' do
          link['data-snippet'] = snippet.id.to_s

          expect(subject.referenced_by([link])).to eq([snippet])
        end
      end

      context 'using a non-existing snippet ID' do
        it 'returns an empty Array' do
          link['data-snippet'] = ''

          expect(subject.referenced_by([link])).to be_empty
        end
      end
    end
  end
end
