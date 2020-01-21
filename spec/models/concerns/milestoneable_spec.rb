# frozen_string_literal: true

require 'spec_helper'

describe Milestoneable do
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }

  shared_examples_for 'an object that can be assigned a milestone' do
    describe 'Validation' do
      describe 'milestone' do
        let(:project) { create(:project, :repository) }
        let(:milestone_id) { milestone.id }

        subject { milestoneable_class.new(params) }

        context 'with correct params' do
          it { is_expected.to be_valid }
        end

        context 'with empty string milestone' do
          let(:milestone_id) { '' }

          it { is_expected.to be_valid }
        end

        context 'with nil milestone id' do
          let(:milestone_id) { nil }

          it { is_expected.to be_valid }
        end

        context 'with a milestone id from another project' do
          let(:milestone_id) { create(:milestone).id }

          it { is_expected.to be_invalid }
        end

        context 'when valid and saving' do
          it 'copies the value to the new milestones relationship' do
            subject.save!

            expect(subject.milestones).to match_array([milestone])
          end

          context 'with old values in milestones relationship' do
            let(:old_milestone) { create(:milestone, project: project) }

            before do
              subject.milestone = old_milestone
              subject.save!
            end

            it 'replaces old values' do
              expect(subject.milestones).to match_array([old_milestone])

              subject.milestone = milestone
              subject.save!

              expect(subject.milestones).to match_array([milestone])
            end

            it 'can nullify the milestone' do
              expect(subject.milestones).to match_array([old_milestone])

              subject.milestone = nil
              subject.save!

              expect(subject.milestones).to match_array([])
            end
          end
        end
      end
    end

    describe '#milestone_available?' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let(:issue) { create(:issue, project: project) }

      def build_milestoneable(milestone_id)
        milestoneable_class.new(project: project, milestone_id: milestone_id)
      end

      it 'returns true with a milestone from the issue project' do
        milestone = create(:milestone, project: project)

        expect(build_milestoneable(milestone.id).milestone_available?).to be_truthy
      end

      it 'returns true with a milestone from the issue project group' do
        milestone = create(:milestone, group: group)

        expect(build_milestoneable(milestone.id).milestone_available?).to be_truthy
      end

      it 'returns true with a milestone from the the parent of the issue project group' do
        parent = create(:group)
        group.update(parent: parent)
        milestone = create(:milestone, group: parent)

        expect(build_milestoneable(milestone.id).milestone_available?).to be_truthy
      end

      it 'returns false with a milestone from another project' do
        milestone = create(:milestone)

        expect(build_milestoneable(milestone.id).milestone_available?).to be_falsey
      end

      it 'returns false with a milestone from another group' do
        milestone = create(:milestone, group: create(:group))

        expect(build_milestoneable(milestone.id).milestone_available?).to be_falsey
      end
    end
  end

  describe '#supports_milestone?' do
    let(:group)   { create(:group) }
    let(:project) { create(:project, group: group) }

    context "for issues" do
      let(:issue) { build(:issue, project: project) }

      it 'returns true' do
        expect(issue.supports_milestone?).to be_truthy
      end
    end

    context "for merge requests" do
      let(:merge_request) { build(:merge_request, target_project: project, source_project: project) }

      it 'returns true' do
        expect(merge_request.supports_milestone?).to be_truthy
      end
    end
  end

  describe 'release scopes' do
    let_it_be(:project) { create(:project) }

    let_it_be(:release_1) { create(:release, tag: 'v1.0', project: project) }
    let_it_be(:release_2) { create(:release, tag: 'v2.0', project: project) }
    let_it_be(:release_3) { create(:release, tag: 'v3.0', project: project) }
    let_it_be(:release_4) { create(:release, tag: 'v4.0', project: project) }

    let_it_be(:milestone_1) { create(:milestone, releases: [release_1], title: 'm1', project: project) }
    let_it_be(:milestone_2) { create(:milestone, releases: [release_1, release_2], title: 'm2', project: project) }
    let_it_be(:milestone_3) { create(:milestone, releases: [release_2, release_4], title: 'm3', project: project) }
    let_it_be(:milestone_4) { create(:milestone, releases: [release_3], title: 'm4', project: project) }
    let_it_be(:milestone_5) { create(:milestone, releases: [release_3], title: 'm5', project: project) }
    let_it_be(:milestone_6) { create(:milestone, title: 'm6', project: project) }

    let_it_be(:issue_1) { create(:issue, milestone: milestone_1, project: project) }
    let_it_be(:issue_2) { create(:issue, milestone: milestone_1, project: project) }
    let_it_be(:issue_3) { create(:issue, milestone: milestone_2, project: project) }
    let_it_be(:issue_4) { create(:issue, milestone: milestone_5, project: project) }
    let_it_be(:issue_5) { create(:issue, milestone: milestone_6, project: project) }
    let_it_be(:issue_6) { create(:issue, project: project) }

    let_it_be(:items) { Issue.all }

    describe '#without_release' do
      it 'returns the issues not tied to any milestone and the ones tied to milestone with no release' do
        expect(items.without_release).to contain_exactly(issue_5, issue_6)
      end
    end

    describe '#any_release' do
      it 'returns all issues tied to a release' do
        expect(items.any_release).to contain_exactly(issue_1, issue_2, issue_3, issue_4)
      end
    end

    describe '#with_release' do
      it 'returns the issues tied a specfic release' do
        expect(items.with_release('v1.0', project.id)).to contain_exactly(issue_1, issue_2, issue_3)
      end

      context 'when a release has a milestone with one issue and another one with no issue' do
        it 'returns that one issue' do
          expect(items.with_release('v2.0', project.id)).to contain_exactly(issue_3)
        end

        context 'when the milestone with no issue is added as a filter' do
          it 'returns an empty list' do
            expect(items.with_release('v2.0', project.id).with_milestone('m3')).to be_empty
          end
        end

        context 'when the milestone with the issue is added as a filter' do
          it 'returns this issue' do
            expect(items.with_release('v2.0', project.id).with_milestone('m2')).to contain_exactly(issue_3)
          end
        end
      end

      context 'when there is no issue under a specific release' do
        it 'returns no issue' do
          expect(items.with_release('v4.0', project.id)).to be_empty
        end
      end

      context 'when a non-existent release tag is passed in' do
        it 'returns no issue' do
          expect(items.with_release('v999.0', project.id)).to be_empty
        end
      end
    end
  end

  context 'Issues' do
    let(:milestoneable_class) { Issue }
    let(:params) do
      {
        title: 'something',
        project: project,
        author: user,
        milestone_id: milestone_id
      }
    end

    it_behaves_like 'an object that can be assigned a milestone'
  end

  context 'MergeRequests' do
    let(:milestoneable_class) { MergeRequest }
    let(:params) do
      {
        title: 'something',
        source_project: project,
        target_project: project,
        source_branch: 'feature',
        target_branch: 'master',
        author: user,
        milestone_id: milestone_id
      }
    end

    it_behaves_like 'an object that can be assigned a milestone'
  end
end
