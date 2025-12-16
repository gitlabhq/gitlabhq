# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::BaseService, feature_category: :wiki do
  let(:project) { double('project') }
  let(:user) { build(:user, id: 1) }
  let(:page) { instance_double(WikiPage, template?: false) }

  before do
    allow(page).to receive(:[]).with(:format).and_return('markdown')
  end

  describe '#increment_usage' do
    let(:subject) { bad_service_class.new(container: project, current_user: user) }

    context 'the class implements internal_event_name incorrectly' do
      let(:bad_service_class) do
        Class.new(described_class) do
          def internal_event_name
            :bad_event
          end
        end
      end

      it 'raises an error on unknown events' do
        expect do
          subject.send(:increment_usage, page)
        end.to raise_error(Gitlab::Tracking::EventValidator::UnknownEventError)
      end
    end
  end

  describe '#track_wiki_event' do
    let(:wiki_page_meta) { instance_double(WikiPage::Meta, project: project) }
    let(:fingerprint) { 'abc123' }
    let(:test_service_class) do
      Class.new(described_class) do
        def event_action
          :created
        end
      end
    end

    subject { test_service_class.new(container: project, current_user: user) }

    before do
      allow(page).to receive_messages(
        find_or_create_meta: wiki_page_meta,
        sha: fingerprint
      )
    end

    context 'when current_user is present' do
      it 'tracks the internal event with correct parameters' do
        expect(subject).to receive(:track_internal_event).with(
          'performed_wiki_action',
          project: project,
          user: user,
          label: 'created',
          meta: wiki_page_meta,
          fingerprint: fingerprint
        )

        subject.send(:track_wiki_event, page)
      end
    end

    context 'when current_user is nil' do
      subject { test_service_class.new(container: project, current_user: nil) }

      it 'does not track the internal event' do
        expect(subject).not_to receive(:track_internal_event)

        subject.send(:track_wiki_event, page)
      end
    end
  end
end
