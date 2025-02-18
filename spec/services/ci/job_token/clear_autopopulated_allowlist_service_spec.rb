# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::ClearAutopopulatedAllowlistService, feature_category: :secrets_management do
  let_it_be(:accessed_project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:service) { described_class.new(accessed_project, maintainer) }

  before_all do
    accessed_project.add_maintainer(maintainer)
    accessed_project.add_developer(developer)
  end

  describe '#execute' do
    context 'with a user with the developer role' do
      let(:service) { described_class.new(accessed_project, developer) }

      it 'raises an access denied error' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    it 'deletes autopopulated group scope links' do
      create(:ci_job_token_group_scope_link, source_project: accessed_project, autopopulated: true)
      create(:ci_job_token_group_scope_link, source_project: accessed_project, autopopulated: false)

      expect do
        service.execute
      end.to change { Ci::JobToken::GroupScopeLink.autopopulated.count }.by(-1)
        .and not_change { Ci::JobToken::ProjectScopeLink.autopopulated.count }
    end

    it 'deletes autopopulated project scope links' do
      create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
        autopopulated: true)
      create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
        autopopulated: false)

      expect do
        service.execute
      end.to not_change { Ci::JobToken::GroupScopeLink.autopopulated.count }
        .and change { Ci::JobToken::ProjectScopeLink.autopopulated.count }.by(-1)
    end

    it 'does not delete non-autopopulated links' do
      create(:ci_job_token_group_scope_link, source_project: accessed_project, autopopulated: false)
      create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
        autopopulated: false)

      expect do
        service.execute
      end.to not_change { Ci::JobToken::GroupScopeLink.autopopulated.count }
        .and not_change { Ci::JobToken::ProjectScopeLink.autopopulated.count }
    end

    it 'executes within a transaction' do
      expect(ApplicationRecord).to receive(:transaction).and_yield

      service.execute
    end

    it 'only deletes links for the given project' do
      create(:ci_job_token_group_scope_link, source_project: accessed_project, autopopulated: true)
      create(:ci_job_token_group_scope_link, source_project: create(:project), autopopulated: true)
      create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
        autopopulated: true)
      create(:ci_job_token_project_scope_link, source_project: create(:project), direction: :inbound,
        autopopulated: true)

      expect do
        service.execute
      end.to change { Ci::JobToken::GroupScopeLink.autopopulated.count }.by(-1)
        .and change { Ci::JobToken::ProjectScopeLink.autopopulated.count }.by(-1)
    end
  end
end
