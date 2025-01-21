# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::Identifier, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

  describe 'project repository' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "project-#{record_id}" }
      let(:expected_container) { project }
      let(:expected_type) { Gitlab::GlRepository::PROJECT }
    end

    # rubocop:disable RSpec/PendingWithoutReason -- waiting for https://gitlab.com/gitlab-org/gitlab/-/issues/219192
    pending 'https://gitlab.com/gitlab-org/gitlab/-/issues/219192' do
      it_behaves_like 'parsing gl_repository identifier' do
        let(:record_id) { project.id }
        let(:identifier) { "project-#{record_id}-code" }
        let(:expected_container) { project }
        let(:expected_type) { Gitlab::GlRepository::PROJECT }
      end
    end
    # rubocop:enable RSpec/PendingWithoutReason

    it_behaves_like 'parsing gl_repository identifier' do
      let(:identifier) { "project-1000000" }
      let(:expected_container) { nil }
      let(:expected_type) { Gitlab::GlRepository::PROJECT }
    end
  end

  describe 'wiki' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "wiki-#{record_id}" }
      let(:expected_container) { project.wiki }
      let(:expected_type) { Gitlab::GlRepository::WIKI }
    end

    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "project-#{record_id}-wiki" }
      let(:expected_container) { project.wiki }
      let(:expected_type) { Gitlab::GlRepository::WIKI }
    end
  end

  describe 'snippet' do
    context 'when PersonalSnippet' do
      it_behaves_like 'parsing gl_repository identifier' do
        let(:record_id) { personal_snippet.id }
        let(:identifier) { "snippet-#{record_id}" }
        let(:expected_container) { personal_snippet }
        let(:expected_type) { Gitlab::GlRepository::SNIPPET }
      end
    end

    context 'when ProjectSnippet' do
      it_behaves_like 'parsing gl_repository identifier' do
        let(:record_id) { project_snippet.id }
        let(:identifier) { "snippet-#{record_id}" }
        let(:expected_container) { project_snippet }
        let(:expected_type) { Gitlab::GlRepository::SNIPPET }
      end
    end
  end

  describe 'design' do
    it_behaves_like 'parsing gl_repository identifier' do
      let(:record_id) { project.id }
      let(:identifier) { "design-#{project.find_or_create_design_management_repository.id}" }
      let(:expected_container) { project.design_management_repository }
      let(:expected_type) { Gitlab::GlRepository::DESIGN }
    end
  end

  context 'when the format is incorrect' do
    where(:identifier) do
      [
        'wiki-noid',
        'foo-2',
        'project-0',
        '2-project',
        'snippet-2-wiki',
        'project-wibble-wiki',
        'wiki-1-project',
        'snippet',
        'project-1-wiki-bar',
        'project-1-project'
      ]
    end

    with_them do
      it 'raises InvalidIdentifier' do
        expect { described_class.parse(identifier) }.to raise_error(described_class::InvalidIdentifier)
      end
    end
  end
end
