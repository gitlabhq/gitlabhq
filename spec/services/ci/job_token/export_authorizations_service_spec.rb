# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::ExportAuthorizationsService, feature_category: :secrets_management do
  let_it_be_with_refind(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:origin_project) { create(:project) }

  let(:accessed_project) { project }
  let(:service) { described_class.new(current_user: user, accessed_project: accessed_project) }

  before_all do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'when user has admin access to the project' do
      let!(:first_authorization) do
        create(:ci_job_token_authorization, accessed_project: accessed_project)
      end

      let!(:second_authorization) do
        create(:ci_job_token_authorization, accessed_project: accessed_project)
      end

      it 'returns a success response with CSV data' do
        result = service.execute

        expect(result).to be_success

        expect(result.payload[:filename]).to start_with("job-token-authorizations-#{accessed_project.id}-")

        rows = result.payload[:data].lines

        expect(rows.count).to eq(3) # 2 authorizations + 1 header row

        expect(rows[0]).to include('Origin Project Path,Last Authorized At (UTC)')
        expect(rows[1]).to include(first_authorization.origin_project.full_path)
        expect(rows[1]).to include(first_authorization.last_authorized_at.utc.iso8601)
      end

      context 'when some origin projects are deleted' do
        before do
          first_authorization.delete
        end

        it 'returns only logs for existing projects without errors' do
          result = service.execute

          expect(result).to be_success

          expect(result.payload[:filename]).to start_with("job-token-authorizations-#{accessed_project.id}-")

          rows = result.payload[:data].lines

          expect(rows.count).to eq(2) # 1 authorizations + 1 header row

          expect(rows[0]).to include('Origin Project Path,Last Authorized At (UTC)')
          expect(rows[1]).to include(second_authorization.origin_project.full_path)
          expect(rows[1]).to include(second_authorization.last_authorized_at.utc.iso8601)
        end
      end
    end

    context 'when user does not have admin access to the project' do
      let(:accessed_project) { create(:project) }

      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Access denied')
        expect(result.reason).to eq(:forbidden)
      end
    end
  end
end
