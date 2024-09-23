# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::RewriteHistoryWorker, feature_category: :source_code_management do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(params) }

    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:user) { create(:user) }

    let(:params) { { project_id: project_id, user_id: user_id, blob_oids: blob_oids } }
    let(:project_id) { project.id }
    let(:user_id) { user.id }
    let(:blob_oids) { ['blob_oid'] }

    let(:job_args) { params }

    it_behaves_like 'an idempotent worker' do
      it 'removes the blob' do
        perform_multiple(job_args)
      end
    end

    it 'executes RewriteHistoryService service' do
      allow_next_instance_of(Repositories::RewriteHistoryService) do |instance|
        expect(instance).to receive(:execute).with(blob_oids: blob_oids, redactions: [])
      end

      perform
    end

    context 'when project id is not valid' do
      let(:project_id) { non_existing_record_id }

      it 'skips the execution' do
        expect(Repositories::RewriteHistoryService).not_to receive(:new)
        perform
      end
    end

    context 'when user id is not valid' do
      let(:user_id) { non_existing_record_id }

      it 'skips the execution' do
        expect(Repositories::RewriteHistoryService).not_to receive(:new)
        perform
      end
    end
  end
end
