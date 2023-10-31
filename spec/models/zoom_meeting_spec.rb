# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZoomMeeting do
  let(:project) { build(:project) }

  describe 'Factory' do
    subject { build(:zoom_meeting) }

    it { is_expected.to be_valid }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
  end

  describe 'scopes' do
    let(:issue) { create(:issue, project: project) }
    let!(:added_meeting) { create(:zoom_meeting, :added_to_issue, issue: issue) }
    let!(:removed_meeting) { create(:zoom_meeting, :removed_from_issue, issue: issue) }

    describe '.added_to_issue' do
      it 'gets only added meetings' do
        meetings_added = described_class.added_to_issue.pluck(:id)

        expect(meetings_added).to include(added_meeting.id)
        expect(meetings_added).not_to include(removed_meeting.id)
      end
    end

    describe '.removed_from_issue' do
      it 'gets only removed meetings' do
        meetings_removed = described_class.removed_from_issue.pluck(:id)

        expect(meetings_removed).to include(removed_meeting.id)
        expect(meetings_removed).not_to include(added_meeting.id)
      end
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:issue) }

    describe 'when importing' do
      subject { build(:zoom_meeting, importing: true) }

      it { is_expected.not_to validate_presence_of(:project) }
      it { is_expected.not_to validate_presence_of(:issue) }
    end

    describe 'url' do
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_length_of(:url).is_at_most(255) }

      shared_examples 'invalid Zoom URL' do
        it do
          expect(subject).to be_invalid
          expect(subject.errors[:url])
            .to contain_exactly('must contain one valid Zoom URL')
        end
      end

      context 'with non-Zoom URL' do
        before do
          subject.url = %(https://non-zoom.url)
        end

        include_examples 'invalid Zoom URL'
      end

      context 'with multiple Zoom-URLs' do
        before do
          subject.url = %(https://zoom.us/j/123 https://zoom.us/j/456)
        end

        include_examples 'invalid Zoom URL'
      end
    end

    describe 'issue association' do
      let(:issue) { build(:issue, project: project) }

      subject { build(:zoom_meeting, project: project, issue: issue) }

      context 'for the same project' do
        it { is_expected.to be_valid }
      end

      context 'for a different project' do
        let(:issue) { build(:issue) }

        it do
          expect(subject).to be_invalid
          expect(subject.errors[:issue])
            .to contain_exactly('must associate the same project')
        end
      end
    end
  end

  describe 'limit number of meetings per issue' do
    shared_examples 'can add meetings' do
      it 'can add new Zoom meetings' do
        create(:zoom_meeting, :added_to_issue, issue: issue)
      end
    end

    shared_examples 'can remove meetings' do
      it 'can remove Zoom meetings' do
        create(:zoom_meeting, :removed_from_issue, issue: issue)
      end
    end

    shared_examples 'cannot add meetings' do
      it 'fails to add a new meeting' do
        expect do
          create(:zoom_meeting, :added_to_issue, issue: issue)
        end.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    let(:issue) { create(:issue, project: project) }

    context 'without meetings' do
      it_behaves_like 'can add meetings'
    end

    context 'when no other meeting is added' do
      before do
        create(:zoom_meeting, :removed_from_issue, issue: issue)
      end

      it_behaves_like 'can add meetings'
    end

    context 'when meeting is added' do
      before do
        create(:zoom_meeting, :added_to_issue, issue: issue)
      end

      it_behaves_like 'cannot add meetings'
    end

    context 'when meeting is added to another issue' do
      let(:another_issue) { create(:issue, project: project) }

      before do
        create(:zoom_meeting, :added_to_issue, issue: another_issue)
      end

      it_behaves_like 'can add meetings'
    end

    context 'when second meeting is removed' do
      before do
        create(:zoom_meeting, :removed_from_issue, issue: issue)
      end

      it_behaves_like 'can remove meetings'
    end
  end
end
