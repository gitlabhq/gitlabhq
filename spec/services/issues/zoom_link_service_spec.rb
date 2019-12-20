# frozen_string_literal: true

require 'spec_helper'

describe Issues::ZoomLinkService do
  set(:user) { create(:user) }
  set(:issue) { create(:issue) }

  let(:project) { issue.project }
  let(:service) { described_class.new(issue, user) }
  let(:zoom_link) { 'https://zoom.us/j/123456789' }

  before do
    project.add_reporter(user)
  end

  shared_context '"added" Zoom meeting' do
    before do
      create(:zoom_meeting, issue: issue)
    end
  end

  shared_context '"removed" zoom meetings' do
    before do
      create(:zoom_meeting, issue: issue, issue_status: :removed)
      create(:zoom_meeting, issue: issue, issue_status: :removed)
    end
  end

  shared_context 'insufficient issue update permissions' do
    before do
      project.add_guest(user)
    end
  end

  shared_context 'insufficient issue create permissions' do
    before do
      expect(service).to receive(:can?).with(user, :create_issue, project).and_return(false)
    end
  end

  describe '#add_link' do
    shared_examples 'can add meeting' do
      it 'appends the new meeting to zoom_meetings' do
        expect(result).to be_success
        expect(ZoomMeeting.canonical_meeting_url(issue)).to eq(zoom_link)
      end

      it 'tracks the add event' do
        expect(Gitlab::Tracking).to receive(:event)
          .with('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
        result
      end

      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)
        result
      end
    end

    shared_examples 'cannot add meeting' do
      it 'cannot add the meeting' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to add a Zoom meeting')
      end

      it 'creates no notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)
        result
      end
    end

    subject(:result) { service.add_link(zoom_link) }

    context 'without existing Zoom meeting' do
      context 'when updating an issue' do
        before do
          allow(issue).to receive(:persisted?).and_return(true)
        end

        include_examples 'can add meeting'

        context 'with insufficient issue update permissions' do
          include_context 'insufficient issue update permissions'
          include_examples 'cannot add meeting'
        end
      end

      context 'when creating an issue' do
        before do
          allow(issue).to receive(:persisted?).and_return(false)
        end

        it 'creates a new zoom meeting' do
          expect(result).to be_success
          expect(result.payload[:zoom_meetings][0].url).to eq(zoom_link)
        end

        context 'with insufficient issue create permissions' do
          include_context 'insufficient issue create permissions'
          include_examples 'cannot add meeting'
        end
      end

      context 'with invalid Zoom url' do
        let(:zoom_link) { 'https://not-zoom.link' }

        include_examples 'cannot add meeting'
      end
    end

    context 'with "added" Zoom meeting' do
      include_context '"added" Zoom meeting'
      include_examples 'cannot add meeting'
    end

    context 'with "added" Zoom meeting and race condition' do
      include_context '"added" Zoom meeting'
      before do
        allow(service).to receive(:can_add_link?).and_return(true)
        allow(issue).to receive(:persisted?).and_return(true)
      end

      include_examples 'cannot add meeting'
    end
  end

  describe '#can_add_link?' do
    subject { service.can_add_link? }

    context 'without "added" zoom meeting' do
      it { is_expected.to eq(true) }

      context 'with insufficient issue update permissions' do
        include_context 'insufficient issue update permissions'

        it { is_expected.to eq(false) }
      end
    end

    context 'with Zoom meeting in the issue description' do
      include_context  '"added" Zoom meeting'

      it { is_expected.to eq(false) }
    end
  end

  describe '#remove_link' do
    shared_examples 'cannot remove meeting' do
      it 'cannot remove the meeting' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to remove a Zoom meeting')
      end

      it 'creates no notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)
        result
      end
    end

    shared_examples 'can remove meeting' do
      it 'creates no notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).to receive(:zoom_link_removed)
        result
      end

      it 'can remove the meeting' do
        expect(result).to be_success
        expect(ZoomMeeting.canonical_meeting_url(issue)).to eq(nil)
      end

      it 'tracks the remove event' do
        expect(Gitlab::Tracking).to receive(:event)
        .with('IncidentManagement::ZoomIntegration', 'remove_zoom_meeting', label: 'Issue ID', value: issue.id)
        result
      end
    end

    subject(:result) { service.remove_link }

    context 'with Zoom meeting' do
      include_context '"added" Zoom meeting'

      context 'with existing issue' do
        before do
          allow(issue).to receive(:persisted?).and_return(true)
        end

        include_examples 'can remove meeting'
      end

      context 'without existing issue' do
        before do
          allow(issue).to receive(:persisted?).and_return(false)
        end

        include_examples 'cannot remove meeting'
      end

      context 'with insufficient issue update permissions' do
        include_context 'insufficient issue update permissions'
        include_examples 'cannot remove meeting'
      end
    end

    context 'without "added" Zoom meeting' do
      include_context '"removed" zoom meetings'
      include_examples 'cannot remove meeting'
    end
  end

  describe '#can_remove_link?' do
    subject { service.can_remove_link? }

    context 'without Zoom meeting' do
      it { is_expected.to eq(false) }
    end

    context 'with only "removed" zoom meetings' do
      include_context '"removed" zoom meetings'
      it { is_expected.to eq(false) }
    end

    context 'with "added" Zoom meeting' do
      include_context '"added" Zoom meeting'
      it { is_expected.to eq(true) }

      context 'with "removed" zoom meetings' do
        include_context '"removed" zoom meetings'
        it { is_expected.to eq(true) }
      end

      context 'with insufficient issue update permissions' do
        include_context 'insufficient issue update permissions'
        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#parse_link' do
    subject { service.parse_link(description) }

    context 'with valid Zoom links' do
      where(:description) do
        [
          'Some text https://zoom.us/j/123456789 more text',
          'Mixed https://zoom.us/j/123456789 http://example.com',
          'Multiple link https://zoom.us/my/name https://zoom.us/j/123456789'
        ]
      end

      with_them do
        it { is_expected.to eq('https://zoom.us/j/123456789') }
      end
    end

    context 'with invalid Zoom links' do
      where(:description) do
        [
          nil,
          '',
          'Text only',
          'Non-Zoom http://example.com',
          'Almost Zoom http://zoom.us'
        ]
      end

      with_them do
        it { is_expected.to eq(nil) }
      end
    end
  end
end
