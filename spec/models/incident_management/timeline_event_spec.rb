# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvent do
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:incident) }
    it { is_expected.to belong_to(:updated_by_user) }
    it { is_expected.to belong_to(:promoted_from_note) }
    it { is_expected.to have_many(:timeline_event_tag_links).class_name('IncidentManagement::TimelineEventTagLink') }

    it do
      is_expected.to have_many(:timeline_event_tags)
      .class_name('IncidentManagement::TimelineEventTag').through(:timeline_event_tag_links)
    end
  end

  describe 'validations' do
    subject { build(:incident_management_timeline_event) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:incident) }
    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_length_of(:note).is_at_most(280).on(:user_input) }
    it { is_expected.to validate_length_of(:note).is_at_most(10_000) }
    it { is_expected.to validate_length_of(:note_html).is_at_most(10_000) }
    it { is_expected.to validate_presence_of(:occurred_at) }
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_length_of(:action).is_at_most(128) }
  end

  describe '.order_occurred_at_asc_id_asc' do
    let_it_be(:occurred_3mins_ago) do
      create(:incident_management_timeline_event, project: project, occurred_at: 3.minutes.ago)
    end

    let_it_be(:occurred_2mins_ago) do
      create(:incident_management_timeline_event, project: project, occurred_at: 2.minutes.ago)
    end

    subject(:order) { described_class.order_occurred_at_asc_id_asc }

    it 'sorts timeline events by occurred_at' do
      is_expected.to eq([occurred_3mins_ago, occurred_2mins_ago, timeline_event])
    end

    context 'when two events occured at the same time' do
      let_it_be(:also_occurred_2mins_ago) do
        create(:incident_management_timeline_event, project: project, occurred_at: occurred_2mins_ago.occurred_at)
      end

      it 'sorts timeline events by occurred_at then sorts by id' do
        occurred_2mins_ago.touch # Interact with record of earlier id to switch default DB ordering

        is_expected.to eq([occurred_3mins_ago, occurred_2mins_ago, also_occurred_2mins_ago, timeline_event])
      end
    end
  end

  describe '#cache_markdown_field' do
    let(:note) { 'note **bold** _italic_ `code` ![image](/path/img.png) :+1:👍' }

    let(:expected_image_html) do
      '<a class="with-attachment-icon" href="/path/img.png" target="_blank" rel="noopener noreferrer">image</a>'
    end

    # rubocop:disable Layout/LineLength
    let(:expected_emoji_html) do
      %(<gl-emoji title="thumbs up" data-name="#{AwardEmoji::THUMBS_UP}" data-unicode-version="6.0">👍</gl-emoji><gl-emoji title="thumbs up" data-name="#{AwardEmoji::THUMBS_UP}" data-unicode-version="6.0">👍</gl-emoji>)
    end

    let(:expected_note_html) do
      %(<p>note <strong>bold</strong> <em>italic</em> <code>code</code> #{expected_image_html} #{expected_emoji_html}</p>)
    end
    # rubocop:enable Layout/LineLength

    before do
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_call_original
    end

    context 'on create' do
      let(:timeline_event) do
        build(:incident_management_timeline_event, project: project, incident: incident, note: note)
      end

      it 'updates note_html', :aggregate_failures do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(timeline_event, :note, { skip_project_check: false })

        expect { timeline_event.save! }.to change { timeline_event.note_html }.to(expected_note_html)
      end
    end

    context 'on update' do
      let(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident) }

      it 'updates note_html', :aggregate_failures do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(timeline_event, :note, { skip_project_check: false })

        expect { timeline_event.update!(note: note) }.to change { timeline_event.note_html }.to(expected_note_html)
      end
    end
  end
end
