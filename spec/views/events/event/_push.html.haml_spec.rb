# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'events/event/_push.html.haml' do
  let(:event) { build_stubbed(:push_event) }
  let(:event_presenter) { event.present }

  context 'with a branch' do
    let(:payload) { build_stubbed(:push_event_payload, event: event) }

    before do
      allow(event).to receive(:push_event_payload).and_return(payload)
    end

    it 'links to the branch' do
      allow(event.project.repository).to receive(:branch_exists?).with(event.ref_name).and_return(true)
      link = project_commits_path(event.project, event.ref_name)

      render partial: 'events/event/push', locals: { event: event_presenter }

      expect(rendered).to have_link(event.ref_name, href: link)
    end

    context 'that has been deleted' do
      it 'does not link to the branch', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/462538' do
        render partial: 'events/event/push', locals: { event: event_presenter }

        expect(rendered).not_to have_link(event.ref_name)
      end
    end

    context 'ref_count is more than 1' do
      let(:payload) do
        build_stubbed(
          :push_event_payload,
          event: event,
          ref_count: 4,
          ref_type: :branch
        )
      end

      it 'includes the count in the text' do
        render partial: 'events/event/push', locals: { event: event_presenter }

        expect(rendered).to include('4 branches')
      end
    end
  end

  context 'with a tag' do
    let(:payload) { build_stubbed(:push_event_payload, event: event, ref_type: :tag, ref: 'v0.1.0') }

    before do
      allow(event).to receive(:push_event_payload).and_return(payload)
    end

    it 'links to the tag' do
      allow(event.project.repository).to receive(:tag_exists?).with(event.ref_name).and_return(true)
      link = project_commits_path(event.project, event.ref_name)

      render partial: 'events/event/push', locals: { event: event_presenter }

      expect(rendered).to have_link(event.ref_name, href: link)
    end

    context 'that has been deleted' do
      it 'does not link to the tag' do
        render partial: 'events/event/push', locals: { event: event_presenter }

        expect(rendered).not_to have_link(event.ref_name)
      end
    end

    context 'ref_count is more than 1' do
      let(:payload) do
        build_stubbed(
          :push_event_payload,
          event: event,
          ref_count: 4,
          ref_type: :tag
        )
      end

      it 'includes the count in the text' do
        render partial: 'events/event/push', locals: { event: event_presenter }

        expect(rendered).to include('4 tags')
      end
    end
  end
end
