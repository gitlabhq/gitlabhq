# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestUserEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  let(:request) { EntityRequest.new(project: merge_request.target_project, current_user: user) }

  let(:entity) do
    described_class.new(user, request: request, merge_request: merge_request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      is_expected.to include(
        :id, :name, :username, :state, :avatar_url, :web_url,
        :can_merge, :can_update_merge_request, :reviewed, :approved
      )
    end

    context 'when `status` is not preloaded' do
      it 'does not expose the availability attribute' do
        expect(subject).not_to include(:availability)
      end
    end

    context 'when the user has not approved the merge-request' do
      it 'exposes that the user has not approved the MR' do
        expect(subject).to include(approved: false)
      end
    end

    context 'when the user has approved the merge-request' do
      before do
        merge_request.approvals.create!(user: user)
      end

      it 'exposes that the user has approved the MR' do
        expect(subject).to include(approved: true)
      end
    end

    context 'when `status` is preloaded' do
      before do
        user.create_status!(availability: :busy)

        user.status # make sure `status` is loaded
      end

      it 'exposes the availibility attribute' do
        expect(subject[:availability]).to eq('busy')
      end
    end

    describe 'performance' do
      let_it_be(:user_a) { create(:user) }
      let_it_be(:user_b) { create(:user) }
      let_it_be(:merge_request_b) { create(:merge_request) }

      it 'is linear in the number of merge requests' do
        pending "See: https://gitlab.com/gitlab-org/gitlab/-/issues/322549"
        baseline = ActiveRecord::QueryRecorder.new do
          ent = described_class.new(user_a, request: request, merge_request: merge_request)
          ent.as_json
        end

        expect do
          a = described_class.new(user_a, request: request, merge_request: merge_request_b)
          b = described_class.new(user_b, request: request, merge_request: merge_request_b)

          a.as_json
          b.as_json
        end.not_to exceed_query_limit(baseline)
      end
    end
  end
end
