# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge requests discussions' do
  # Further tests can be found at merge_requests_controller_spec.rb
  describe 'GET /:namespace/:project/-/merge_requests/:iid/discussions' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.owner }
    let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    before do
      project.add_developer(user)
      login_as(user)
    end

    def send_request
      get discussions_namespace_project_merge_request_path(namespace_id: project.namespace, project_id: project, id: merge_request.iid)
    end

    it 'returns 200' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    # https://docs.gitlab.com/ee/development/query_recorder.html#use-request-specs-instead-of-controller-specs
    it 'avoids N+1 DB queries', :request_store do
      send_request # warm up

      create(:diff_note_on_merge_request, noteable: merge_request,
             project: merge_request.project)
      control = ActiveRecord::QueryRecorder.new { send_request }

      create(:diff_note_on_merge_request, noteable: merge_request,
             project: merge_request.project)

      expect do
        send_request
      end.not_to exceed_query_limit(control)
    end

    it 'limits Gitaly queries', :request_store do
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        create_list(:diff_note_on_merge_request, 7, noteable: merge_request,
                    project: merge_request.project)
      end

      # The creations above write into the Gitaly counts
      Gitlab::GitalyClient.reset_counts

      expect { send_request }
        .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(4)
    end

    context 'caching', :use_clean_rails_memory_store_caching do
      let!(:first_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
      let!(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note, noteable: merge_request, project: project) }
      let!(:award_emoji) { create(:award_emoji, awardable: first_note) }

      before do
        # Make a request to cache the discussions
        send_request
      end

      shared_examples 'cache miss' do
        it 'does not hit a warm cache' do
          expect_next_instance_of(DiscussionSerializer) do |serializer|
            expect(serializer).to receive(:represent) do |arg|
              expect(arg.notes).to contain_exactly(*changed_notes)
            end.and_call_original
          end

          send_request
        end
      end

      it 'gets cached on subsequent requests' do
        expect_next_instance_of(DiscussionSerializer) do |serializer|
          expect(serializer).not_to receive(:represent)
        end

        send_request
      end

      context 'when a note in a discussion got updated' do
        before do
          first_note.update!(updated_at: 1.minute.from_now)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when a note in a discussion got resolved' do
        before do
          travel_to(1.minute.from_now) do
            first_note.resolve!(user)
          end
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when a note is added to a discussion' do
        let!(:third_note) { create(:diff_note_on_merge_request, in_reply_to: first_note, noteable: merge_request, project: project) }

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note, third_note] }
        end
      end

      context 'when a note is removed from a discussion' do
        before do
          second_note.destroy!
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note] }
        end
      end

      context 'when an emoji is awarded to a note in discussion' do
        before do
          travel_to(1.minute.from_now) do
            create(:award_emoji, awardable: first_note)
          end
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when an award emoji is removed from a note in discussion' do
        before do
          travel_to(1.minute.from_now) do
            award_emoji.destroy!
          end
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when cached markdown version gets bump' do
        before do
          settings = Gitlab::CurrentSettings.current_application_settings
          settings.update!(local_markdown_version: settings.local_markdown_version + 1)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when merge_request_discussion_cache is disabled' do
        before do
          stub_feature_flags(merge_request_discussion_cache: false)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end
    end
  end
end
