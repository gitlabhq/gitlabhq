# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Release do
  let_it_be(:project) { create(:project) }

  let(:release) { create(:release, project: project) }
  let(:evidence) { release.evidences.first }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(release, current_user: user, include_html_description: include_html_description).as_json }
  let(:include_html_description) { false }

  before do
    ::Releases::CreateEvidenceService.new(release).execute
  end

  describe 'evidences' do
    context 'when the current user can download code' do
      let(:entity_evidence) { entity[:evidences].first }

      it 'exposes the evidence sha and the json path' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :download_code, project).and_return(true)

        expect(entity_evidence[:sha]).to eq(evidence.summary_sha)
        expect(entity_evidence[:collected_at]).to eq(evidence.collected_at)
        expect(entity_evidence[:filepath]).to eq(
          Gitlab::Routing.url_helpers.namespace_project_evidence_url(
            namespace_id: project.namespace,
            project_id: project,
            tag: release,
            id: evidence.id,
            format: :json))
      end
    end

    context 'when the current user cannot download code' do
      it 'does not expose any evidence data' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :download_code, project).and_return(false)

        expect(entity.keys).not_to include(:evidences)
      end
    end
  end

  describe 'description_html' do
    let(:issue) { create(:issue, :confidential, project: project) }
    let(:issue_path) { Gitlab::Routing.url_helpers.project_issue_path(project, issue) }
    let(:issue_title) { 'title="%s"' % issue.title }
    let(:release) { create(:release, project: project, description: "Now shipping #{issue.to_reference}") }

    subject(:description_html) { entity.as_json['description_html'] }

    it 'is inexistent' do
      expect(description_html).to be_nil
    end

    context 'when include_html_description option is true' do
      let(:include_html_description) { true }

      it 'renders special references if current user has access' do
        project.add_reporter(user)

        expect(description_html).to include(issue_path)
        expect(description_html).to include(issue_title)
      end

      it 'does not render special references if current user has no access' do
        project.add_guest(user)

        expect(description_html).not_to include(issue_path)
        expect(description_html).not_to include(issue_title)
      end
    end
  end
end
