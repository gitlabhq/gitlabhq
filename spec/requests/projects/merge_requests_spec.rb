# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge requests actions', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:merge_request) do
    create(
      :merge_request_with_diffs,
      target_project: project,
      source_project: project,
      assignees: [user],
      reviewers: [user2]
    )
  end

  let(:user) { project.first_owner }
  let(:user2) { create(:user) }

  before do
    project.add_maintainer(user2)
    sign_in(user)
  end

  describe 'GET /:namespace/:project/-/merge_requests/:iid' do
    describe 'as json' do
      def send_request(extra_params = {})
        params = {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          format: :json
        }

        get namespace_project_merge_request_path(params.merge(extra_params))
      end

      context 'with caching', :use_clean_rails_memory_store_caching do
        let(:params) { {} }

        context 'for sidebar_extras' do
          let(:params) { { serializer: 'sidebar_extras' } }

          shared_examples_for 'a non-cached request' do
            it 'serializes merge request' do
              expect_next_instance_of(MergeRequestSerializer) do |instance|
                expect(instance).to receive(:represent)
                  .with(an_instance_of(MergeRequest), serializer: 'sidebar_extras')
                  .and_call_original
              end

              send_request(params)
            end
          end

          context 'when the request has not been cached' do
            it_behaves_like 'a non-cached request'
          end

          context 'when the request has already been cached' do
            before do
              send_request(params)
            end

            it 'does not serialize merge request again' do
              expect_next_instance_of(MergeRequestSerializer) do |instance|
                expect(instance).not_to receive(:represent)
              end

              send_request(params)
            end

            context 'when the merge request is updated' do
              def update_service(params)
                MergeRequests::UpdateService.new(project: project, current_user: user, params: params).execute(merge_request)
              end

              context 'when the logged in user is different' do
                before do
                  sign_in(user2)
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the assignee is changed' do
                before do
                  update_service(assignee_ids: [])
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the existing assignee gets updated' do
                before do
                  user.update_attribute(:avatar, 'uploads/avatar.png')
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the reviewer is changed' do
                before do
                  update_service(reviewer_ids: [])
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the existing reviewer gets updated' do
                before do
                  user2.update_attribute(:avatar, 'uploads/avatar.png')
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the time_estimate is changed' do
                before do
                  update_service(time_estimate: 7200)
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when the spend_time is changed' do
                before do
                  update_service(spend_time: { duration: 7200, user_id: user.id, spent_at: Time.now, note_id: nil })
                end

                it_behaves_like 'a non-cached request'
              end

              context 'when a user leaves a note' do
                before do
                  # We have 1 minute ThrottledTouch to account for.
                  # It's not ideal as it means that our participants cache could be stale for about a day if a new note is created by another person or gets a mention.
                  travel_to(Time.current + 61) do
                    Notes::CreateService.new(project, user2, { note: 'Looks good', noteable_type: 'MergeRequest', noteable_id: merge_request.id }).execute
                  end
                end

                it_behaves_like 'a non-cached request'
              end
            end
          end
        end

        context 'for other serializer' do
          let(:params) { { serializer: 'basic' } }

          it 'does not use cache' do
            expect(Rails.cache).not_to receive(:fetch).with(/cache:gitlab:MergeRequestSerializer:/).and_call_original

            send_request(params)
          end
        end
      end
    end
  end
end
