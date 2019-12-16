# frozen_string_literal: true

require 'spec_helper'

describe ChatMessage::MergeMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
          name: 'Test User',
          username: 'test.user',
          avatar_url: 'http://someavatar.com'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',

      object_attributes: {
        title: "Merge Request title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
        state: 'opened',
        description: 'merge request description',
        source_branch: 'source_branch',
        target_branch: 'target_branch'
      }
    }
  end

  # Integration point in EE
  context 'when state is overridden' do
    it 'respects the overridden state' do
      allow(subject).to receive(:state_or_action_text) { 'devoured' }

      aggregate_failures do
        expect(subject.summary).not_to include('opened')
        expect(subject.summary).to include('devoured')

        activity_title = subject.activity[:title]

        expect(activity_title).not_to include('opened')
        expect(activity_title).to include('devoured')
      end
    end
  end

  context 'without markdown' do
    let(:color) { '#345' }

    context 'open' do
      it 'returns a message regarding opening of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) opened <http://somewhere.com/-/merge_requests/100|!100 *Merge Request title*> in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'close' do
      before do
        args[:object_attributes][:state] = 'closed'
      end
      it 'returns a message regarding closing of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) closed <http://somewhere.com/-/merge_requests/100|!100 *Merge Request title*> in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    context 'open' do
      it 'returns a message regarding opening of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) opened [!100 *Merge Request title*](http://somewhere.com/-/merge_requests/100) in [project_name](http://somewhere.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Merge Request opened by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[!100 *Merge Request title*](http://somewhere.com/-/merge_requests/100)',
          image: 'http://someavatar.com'
        })
      end
    end

    context 'close' do
      before do
        args[:object_attributes][:state] = 'closed'
      end

      it 'returns a message regarding closing of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) closed [!100 *Merge Request title*](http://somewhere.com/-/merge_requests/100) in [project_name](http://somewhere.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Merge Request closed by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[!100 *Merge Request title*](http://somewhere.com/-/merge_requests/100)',
          image: 'http://someavatar.com'
        })
      end
    end
  end
end
