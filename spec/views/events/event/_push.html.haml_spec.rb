require 'spec_helper'

describe 'events/event/_push.html.haml' do
  let(:event) { build_stubbed(:push_event) }

  context 'with a branch' do
    let(:payload) { build_stubbed(:push_event_payload, event: event) }

    before do
      allow(event).to receive(:push_event_payload).and_return(payload)
    end

    it 'links to the branch' do
      allow(event.project.repository).to receive(:branch_exists?).with(event.ref_name).and_return(true)
      link = project_commits_path(event.project, event.ref_name)

      render partial: 'events/event/push', locals: { event: event }

      expect(rendered).to have_link(event.ref_name, href: link)
    end

    context 'that has been deleted' do
      it 'does not link to the branch' do
        render partial: 'events/event/push', locals: { event: event }

        expect(rendered).not_to have_link(event.ref_name)
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

      render partial: 'events/event/push', locals: { event: event }

      expect(rendered).to have_link(event.ref_name, href: link)
    end

    context 'that has been deleted' do
      it 'does not link to the tag' do
        render partial: 'events/event/push', locals: { event: event }

        expect(rendered).not_to have_link(event.ref_name)
      end
    end
  end
end
