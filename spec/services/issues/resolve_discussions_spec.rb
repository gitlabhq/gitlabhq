require 'spec_helper.rb'

describe Issues::ResolveDiscussions do
  class DummyService < Issues::BaseService
    include ::Issues::ResolveDiscussions

    def initialize(*args)
      super
      filter_resolve_discussion_params
    end
  end

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
  end

  describe "for resolving discussions" do
    let(:discussion) { create(:diff_note_on_merge_request, project: project, note: "Almost done").to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:other_merge_request) { create(:merge_request, source_project: project, source_branch: "fix") }

    describe "#merge_request_for_resolving_discussion" do
      let(:service) { DummyService.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid) }

      it "finds the merge request" do
        expect(service.merge_request_to_resolve_discussions_of).to eq(merge_request)
      end

      it "only queries for the merge request once" do
        fake_finder = double
        fake_results = double

        expect(fake_finder).to receive(:execute).and_return(fake_results).exactly(1)
        expect(fake_results).to receive(:find_by).exactly(1)
        expect(MergeRequestsFinder).to receive(:new).and_return(fake_finder).exactly(1)

        2.times { service.merge_request_to_resolve_discussions_of }
      end
    end

    describe "#discussions_to_resolve" do
      it "contains a single discussion when matching merge request and discussion are passed" do
        service = DummyService.new(
          project,
          user,
          discussion_to_resolve: discussion.id,
          merge_request_to_resolve_discussions_of: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id)
      end

      it "contains all discussions when only a merge request is passed" do
        second_discussion = Discussion.new([create(:diff_note_on_merge_request,
                                                  noteable: merge_request,
                                                  project: merge_request.target_project,
                                                  line_number: 15)])
        service = DummyService.new(
          project,
          user,
          merge_request_to_resolve_discussions_of: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id, second_discussion.id)
      end

      it "contains only unresolved discussions" do
        _second_discussion = Discussion.new([create(:diff_note_on_merge_request, :resolved,
                                                   noteable: merge_request,
                                                   project: merge_request.target_project,
                                                   line_number: 15
                                                   )])
        service = DummyService.new(
          project,
          user,
          merge_request_to_resolve_discussions_of: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id)
      end

      it "is empty when a discussion and another merge request are passed" do
        service = DummyService.new(
          project,
          user,
          discussion_to_resolve: discussion.id,
          merge_request_to_resolve_discussions_of: other_merge_request.iid
        )

        expect(service.discussions_to_resolve).to be_empty
      end
    end
  end
end
