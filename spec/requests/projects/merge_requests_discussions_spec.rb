# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge requests discussions', feature_category: :source_code_management do
  # Further tests can be found at merge_requests_controller_spec.rb
  describe 'GET /:namespace/:project/-/merge_requests/:iid/discussions' do
    let(:project) { create(:project, :repository, :public) }
    let(:owner) { project.first_owner }
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    before do
      project.add_maintainer(owner)
      project.add_developer(user)
      login_as(user)
    end

    # rubocop:disable RSpec/InstanceVariable
    def send_request
      get(
        discussions_namespace_project_merge_request_path(namespace_id: project.namespace, project_id: project, id: merge_request.iid),
        headers: { 'If-None-Match' => @etag }
      )

      @etag = response.etag
    end
    # rubocop:enable RSpec/InstanceVariable

    it 'avoids N+1 DB queries', :request_store do
      send_request # warm up

      create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project)
      control = ActiveRecord::QueryRecorder.new { send_request }

      create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project)

      expect { send_request }.not_to exceed_query_limit(control)
    end

    it 'returns 200' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'limits Gitaly queries', :request_store do
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        create_list(:diff_note_on_merge_request, 7, noteable: merge_request, project: merge_request.project)
      end

      # The creations above write into the Gitaly counts
      Gitlab::GitalyClient.reset_counts

      expect { send_request }
        .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(4)
    end

    context 'caching' do
      let(:reference) { create(:issue, project: project) }
      let(:author) { create(:user) }
      let!(:first_note) { create(:diff_note_on_merge_request, author: author, noteable: merge_request, project: project, note: "reference: #{reference.to_reference}") }
      let!(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note, noteable: merge_request, project: project) }
      let!(:award_emoji) { create(:award_emoji, awardable: first_note) }
      let!(:author_membership) { project.add_maintainer(author) }

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

      shared_examples 'cache hit' do
        it 'gets cached on subsequent requests' do
          expect(DiscussionSerializer).not_to receive(:new)

          send_request
        end
      end

      before do
        send_request
      end

      it_behaves_like 'cache hit'

      context 'when a note in a discussion got updated' do
        before do
          first_note.update!(updated_at: 1.minute.from_now)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when a note in a discussion got its reference state updated' do
        before do
          reference.close!
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

      context 'when the diff note position changes' do
        before do
          # This replicates a position change wherein timestamps aren't updated
          # which is why `save(touch: false)` is utilized. This is the same
          # approach being used in Discussions::UpdateDiffPositionService which
          # is responsible for updating the positions of diff discussions when
          # MR updates.
          first_note.position = Gitlab::Diff::Position.new(
            old_path: first_note.position.old_path,
            new_path: first_note.position.new_path,
            old_line: first_note.position.old_line,
            new_line: first_note.position.new_line + 1,
            diff_refs: first_note.position.diff_refs
          )

          first_note.save!(touch: false)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when the HEAD diff note position changes' do
        before do
          # This replicates a DiffNotePosition change. This is the same approach
          # being used in Discussions::CaptureDiffNotePositionService which is
          # responsible for updating/creating DiffNotePosition of a diff discussions
          # in relation to HEAD diff.
          new_position = Gitlab::Diff::Position.new(
            old_path: first_note.position.old_path,
            new_path: first_note.position.new_path,
            old_line: first_note.position.old_line,
            new_line: first_note.position.new_line + 1,
            diff_refs: first_note.position.diff_refs
          )

          DiffNotePosition.create_or_update_for(
            first_note,
            diff_type: :head,
            position: new_position,
            line_code: 'bd4b7bfff3a247ccf6e3371c41ec018a55230bcc_534_521'
          )
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when author detail changes' do
        before do
          author.update!(name: "#{author.name} (Updated)")
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when author status changes' do
        before do
          Users::SetStatusService.new(author, message: "updated status").execute
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when author role changes' do
        before do
          Members::UpdateService.new(owner, access_level: Gitlab::Access::GUEST, source: project).execute(author_membership)
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end

      context 'when current_user role changes' do
        before do
          Members::UpdateService.new(owner, access_level: Gitlab::Access::GUEST, source: project).execute(project.member(user))
        end

        it_behaves_like 'cache miss' do
          let(:changed_notes) { [first_note, second_note] }
        end
      end
    end
  end
end
