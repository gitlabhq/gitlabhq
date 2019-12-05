# frozen_string_literal: true

require 'spec_helper'

describe API::Entities::Release do
  let_it_be(:project) { create(:project) }
  let_it_be(:release) { create(:release, :with_evidence, project: project) }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(release, current_user: user) }

  subject { entity.as_json }

  describe 'evidence' do
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
end
