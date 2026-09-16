# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::MergeMessage, feature_category: :integrations do
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

  it_behaves_like Integrations::ChatMessage

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

  context 'when reviewers change' do
    before do
      args[:object_attributes][:action] = 'update'
    end

    context 'when a reviewer is requested' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [],
            current: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed' }]
          }
        }
      end

      it 'names the requested reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) requested a review from Jane Doe (jane) of merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when several reviewers are requested at once' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [],
            current: [
              { name: 'Jane Doe', username: 'jane', state: 'unreviewed' },
              { name: 'John Roe', username: 'john', state: 'unreviewed' }
            ]
          }
        }
      end

      it 'names every requested reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) requested a review from Jane Doe (jane) and John Roe (john) of merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when all reviewers are removed' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed' }],
            current: []
          }
        }
      end

      it 'returns a message regarding the reviewers being removed' do
        expect(subject.pretext).to eq(
          'Test User (test.user) removed all reviewers from merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when a reviewer is added alongside existing reviewers' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed' }],
            current: [
              { name: 'Jane Doe', username: 'jane', state: 'unreviewed' },
              { name: 'John Roe', username: 'john', state: 'unreviewed' }
            ]
          }
        }
      end

      it 'names only the newly requested reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) requested a review from John Roe (john) of merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when a review is re-requested from an existing reviewer' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [
              { name: 'Jane Doe', username: 'jane', state: 'reviewed', re_requested: false },
              { name: 'John Roe', username: 'john', state: 'unreviewed', re_requested: false }
            ],
            current: [
              { name: 'Jane Doe', username: 'jane', state: 'unreviewed', re_requested: true },
              { name: 'John Roe', username: 'john', state: 'unreviewed', re_requested: false }
            ]
          }
        }
      end

      it 'names the re-requested reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) requested a review from Jane Doe (jane) of merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when only a reviewer state changes without a re-request' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed', re_requested: false }],
            current: [{ name: 'Jane Doe', username: 'jane', state: 'reviewed', re_requested: false }]
          }
        }
      end

      it 'falls back to the merge request state' do
        expect(subject.pretext).to eq(
          'Test User (test.user) opened merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when a single reviewer is removed while others remain' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [
              { name: 'Jane Doe', username: 'jane', state: 'unreviewed' },
              { name: 'John Roe', username: 'john', state: 'unreviewed' }
            ],
            current: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed' }]
          }
        }
      end

      it 'names the removed reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) removed John Roe (john) as reviewer from merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when several reviewers are removed while others remain' do
      before do
        args[:changes] = {
          reviewers: {
            previous: [
              { name: 'Jane Doe', username: 'jane', state: 'unreviewed' },
              { name: 'John Roe', username: 'john', state: 'unreviewed' },
              { name: 'Amy Roe', username: 'amy', state: 'unreviewed' }
            ],
            current: [{ name: 'Jane Doe', username: 'jane', state: 'unreviewed' }]
          }
        }
      end

      it 'names every removed reviewer in the message' do
        expect(subject.pretext).to eq(
          'Test User (test.user) removed John Roe (john) and Amy Roe (amy) as reviewers from merge request '\
          '<http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when the update does not change reviewers' do
      it 'falls back to the merge request state' do
        expect(subject.pretext).to eq(
          'Test User (test.user) opened merge request <http://somewhere.com/-/merge_requests/100|!100 *Merge request title*> '\
          'in <http://somewhere.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end
  end
end
