# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::MergeMessage do
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
        title: "Merge request title\nSecond line",
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

  context 'without markdown' do
    let(:color) { '#345' }

    context 'open' do
      it 'returns a message regarding opening of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) opened merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'close' do
      before do
        args[:object_attributes][:state] = 'closed'
      end
      it 'returns a message regarding closing of merge requests' do
        expect(subject.pretext).to eq(
          'Test User (test.user) closed merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> in <http://somewhere.com|project_name>')
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
          'Test User (test.user) opened merge request [!100 *Merge request title*](http://somewhere.com/-/merge_requests/100) in [project_name](http://somewhere.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Merge request opened by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[!100 *Merge request title*](http://somewhere.com/-/merge_requests/100)',
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
          'Test User (test.user) closed merge request [!100 *Merge request title*](http://somewhere.com/-/merge_requests/100) in [project_name](http://somewhere.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Merge request closed by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[!100 *Merge request title*](http://somewhere.com/-/merge_requests/100)',
          image: 'http://someavatar.com'
        })
      end
    end
  end

  context 'approved' do
    before do
      args[:object_attributes][:action] = 'approved'
    end

    it 'returns a message regarding completed approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) approved merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'unapproved' do
    before do
      args[:object_attributes][:action] = 'unapproved'
    end

    it 'returns a message regarding revocation of completed approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) unapproved merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'approval' do
    before do
      args[:object_attributes][:action] = 'approval'
    end

    it 'returns a message regarding added approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) added their approval to merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'unapproval' do
    before do
      args[:object_attributes][:action] = 'unapproval'
    end

    it 'returns a message regarding revoking approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) removed their approval from merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end
end
