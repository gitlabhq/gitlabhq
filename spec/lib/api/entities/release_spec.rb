# frozen_string_literal: true

require 'spec_helper'

describe API::Entities::Release do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let(:entity) { described_class.new(release, current_user: user) }

  describe 'evidence' do
    let(:release) { create(:release, :with_evidence, project: project) }

    subject { entity.as_json }

    context 'when the current user can download code' do
      it 'exposes the evidence sha and the json path' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :download_code, project).and_return(true)

        expect(subject[:evidence_sha]).to eq(release.evidence_sha)
        expect(subject[:assets][:evidence_file_path]).to eq(
          Gitlab::Routing.url_helpers.evidence_project_release_url(project,
                                                                   release.tag,
                                                                   format: :json)
        )
      end
    end

    context 'when the current user cannot download code' do
      it 'does not expose any evidence data' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :download_code, project).and_return(false)

        expect(subject.keys).not_to include(:evidence_sha)
        expect(subject[:assets].keys).not_to include(:evidence_file_path)
      end
    end
  end

  describe 'description_html' do
    let(:issue) { create(:issue, :confidential, project: project) }
    let(:issue_path) { Gitlab::Routing.url_helpers.project_issue_path(project, issue) }
    let(:issue_title) { 'title="%s"' % issue.title }
    let(:release) { create(:release, project: project, description: "Now shipping #{issue.to_reference}") }

    subject(:description_html) { entity.as_json[:description_html] }

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
