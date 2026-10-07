# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects raw controller', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }

  describe 'GET #show ref_type on an ambiguous ref' do
    let(:raw_path) { "/#{project.full_path}/-/raw/v1.1.0/bar/branch-test.txt" }
    let(:branch_blob) { project.repository.blob_at('refs/heads/v1.1.0', 'bar/branch-test.txt') }

    it 'uses an ambiguous ref that resolves differently by ref_type' do
      expect(project.repository.branch_exists?('v1.1.0')).to be(true)
      expect(project.repository.tag_exists?('v1.1.0')).to be(true)
      expect(branch_blob).to be_present
      expect(project.repository.blob_at('refs/tags/v1.1.0', 'bar/branch-test.txt')).to be_nil
    end

    context 'when ref_type=heads is in the query string' do
      it 'exposes ref_type through a real HashWithIndifferentAccess query_parameters' do
        captured = nil
        allow_next_instance_of(Projects::RawController) do |controller|
          allow(controller).to receive(:assign_ref_vars).and_wrap_original do |method, *args|
            captured = controller.request.query_parameters
            method.call(*args)
          end
        end

        get "#{raw_path}?ref_type=heads"

        expect(captured).to be_an(ActiveSupport::HashWithIndifferentAccess)
        expect(captured[:ref_type]).to eq('heads')
        expect(captured[:ref_type]).to eq(captured['ref_type'])
      end

      it 'resolves the branch ref and serves its blob' do
        allow(Gitlab::Workhorse).to receive(:send_git_blob).and_call_original

        get "#{raw_path}?ref_type=heads"

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Workhorse).to have_received(:send_git_blob).with(
          anything, have_attributes(id: branch_blob.id)
        )
      end
    end

    context 'when ref_type=heads is only in the request body' do
      it 'reaches params but not query_parameters, and is ignored' do
        captured = {}
        allow_next_instance_of(Projects::RawController) do |controller|
          allow(controller).to receive(:assign_ref_vars).and_wrap_original do |method, *args|
            captured = {
              params: controller.params[:ref_type],
              query: controller.request.query_parameters[:ref_type]
            }
            method.call(*args)
          end
        end

        get raw_path, params: { ref_type: 'heads' }, as: :json

        expect(captured[:params]).to eq('heads')
        expect(captured[:query]).to be_nil
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
