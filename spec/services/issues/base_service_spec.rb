require 'spec_helper.rb'

describe Issues::BaseService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :developer]
  end

  describe "for resolving discussions" do
    let(:discussion) { Discussion.new([create(:diff_note_on_merge_request, project: project, note: "Almost done")]) }
    let(:merge_request) { discussion.noteable }
    let(:other_merge_request) { create(:merge_request, source_project: project, source_branch: "other") }

    describe "#for_single_discussion" do
      it "is true when only a discussion is passed" do
        service = described_class.new(project, user, discussion_to_resolve: discussion)

        expect(service.for_single_discussion?).to be_truthy
      end

      it "is true when matching merge request and discussion are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion,
          merge_request_for_resolving_discussions: merge_request
        )

        expect(service.for_single_discussion?).to be_truthy
      end

      it "is false when a discussion and another merge request are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion,
          merge_request_for_resolving_discussions: other_merge_request
        )

        expect(service.for_single_discussion?).to be_falsy
      end
    end

    describe "#for_all_discussions_in_a_merge_request" do
      it "is true when only a merge request is passed" do
        service = described_class.new(project, user, merge_request_for_resolving_discussions: merge_request)

        expect(service.for_all_discussions_in_a_merge_request?).to be_truthy
      end

      it "is false when matching merge request and discussion are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion,
          merge_request_for_resolving_discussions: merge_request
        )

        expect(service.for_all_discussions_in_a_merge_request?).to be_falsy
      end
    end

    describe "#discussions_to_resolve" do
      it "only contains a single discussion when only a discussion is passed" do
        service = described_class.new(project, user, discussion_to_resolve: discussion)

        expect(service.discussions_to_resolve).to contain_exactly(discussion)
      end

      it "is contains a single discussion when matching merge request and discussion are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion,
          merge_request_for_resolving_discussions: merge_request
        )

        expect(service.discussions_to_resolve).to contain_exactly(discussion)
      end

      it "contains all discussions when only a merge request is passed" do
        second_discussion = Discussion.new([create(:diff_note_on_merge_request,
                                                  noteable: merge_request,
                                                  project: merge_request.target_project,
                                                  line_number: 15)])
        service = described_class.new(
          project,
          user,
          merge_request_for_resolving_discussions: merge_request
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id, second_discussion.id)
      end

      it "is empty when a discussion and another merge request are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion,
          merge_request_for_resolving_discussions: other_merge_request
        )

        expect(service.discussions_to_resolve).to be_empty
      end
    end
  end
end
