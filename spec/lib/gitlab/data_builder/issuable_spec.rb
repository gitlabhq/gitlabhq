# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Issuable do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:reusable_project) { create(:project, :repository, group: group) }

  # This shared example requires a `builder` and `user` variable
  shared_examples 'issuable hook data' do |kind, hook_data_issuable_builder_class|
    let(:data) { builder.build(user: user, action: 'updated') }

    include_examples 'project hook data' do
      let(:project) { builder.issuable.project }
    end

    include_examples 'deprecated repository hook data'

    context "with a #{kind}" do
      it 'contains issuable data' do
        expected_object_attributes = hook_data_issuable_builder_class.new(issuable).build.merge(action: 'updated')

        expect(data[:object_kind]).to eq(kind)
        expect(data[:user]).to eq(user.hook_attrs)
        expect(data[:project]).to eq(builder.issuable.project.hook_attrs)
        expect(data[:object_attributes]).to eq(expected_object_attributes)
        expect(data[:changes]).to eq({})
        expect(data[:repository]).to eq(builder.issuable.project.hook_attrs.slice(:name, :url, :description, :homepage))
      end

      it 'does not contain certain keys' do
        expect(data).not_to have_key(:assignees)
        expect(data).not_to have_key(:assignee)
      end

      it 'does not include action attribute when action is not given' do
        data = described_class.new(issuable).build(user: user)

        expect(data[:object_attributes]).not_to have_key(:action)
      end

      describe 'changes are given' do
        let(:changes) do
          {
            cached_markdown_version: %w[foo bar],
            description: ['A description', 'A cool description'],
            description_html: %w[foo bar],
            in_progress_merge_commit_sha: %w[foo bar],
            lock_version: %w[foo bar],
            merge_jid: %w[foo bar],
            title: ['A title', 'Hello World'],
            title_html: %w[foo bar],
            labels: [
              [{ id: 1, title: 'foo' }],
              [{ id: 1, title: 'foo' }, { id: 2, title: 'bar' }]
            ],
            total_time_spent: [1, 2],
            assignees: [
              [],
              [{
                name: "Foo Bar",
                username: "foobar",
                avatar_url: "http://www.example.com/my-avatar.jpg"
              }]
            ]
          }
        end

        let(:data) { builder.build(user: user, changes: changes, action: 'updated') }

        it 'populates the :changes hash' do
          expect(data[:changes]).to match(hash_including({
            title: { previous: 'A title', current: 'Hello World' },
            description: { previous: 'A description', current: 'A cool description' },
            labels: {
              previous: [{ id: 1, title: 'foo' }],
              current: [{ id: 1, title: 'foo' }, { id: 2, title: 'bar' }]
            },
            total_time_spent: {
              previous: 1,
              current: 2
            },
            assignees: {
              previous: [],
              current: [{
                  name: "Foo Bar",
                  username: "foobar",
                  avatar_url: "http://www.example.com/my-avatar.jpg"
                }]
            }
          }))
        end

        it 'does not contain certain keys' do
          expect(data[:changes]).not_to have_key('cached_markdown_version')
          expect(data[:changes]).not_to have_key('description_html')
          expect(data[:changes]).not_to have_key('lock_version')
          expect(data[:changes]).not_to have_key('title_html')
          expect(data[:changes]).not_to have_key('in_progress_merge_commit_sha')
          expect(data[:changes]).not_to have_key('merge_jid')
        end
      end
    end
  end

  describe '#build' do
    it_behaves_like 'issuable hook data', 'issue', Gitlab::HookData::IssueBuilder do
      let_it_be(:issuable) { create(:issue, description: 'A description', project: reusable_project) }
      let(:builder) { described_class.new(issuable) }
    end

    it_behaves_like 'issuable hook data', 'merge_request', Gitlab::HookData::MergeRequestBuilder do
      let_it_be(:issuable) { create(:merge_request, description: 'A description', source_project: reusable_project) }
      let(:builder) { described_class.new(issuable) }
    end

    context 'issue is assigned' do
      let(:issue) { create(:issue, assignees: [user], project: reusable_project) }
      let(:data) { described_class.new(issue).build(user: user, action: 'updated') }

      it 'returns correct hook data' do
        expect(data[:object_attributes]['assignee_id']).to eq(user.id)
        expect(data[:assignees].first).to eq(user.hook_attrs)
        expect(data).not_to have_key(:assignee)
        expect(data).not_to have_key(:reviewers)
      end
    end

    context 'when issuable is a group level work item' do
      let(:work_item) { create(:work_item, namespace: group, description: 'work item description') }

      it 'returns correct hook data', :aggregate_failures do
        data = described_class.new(work_item).build(user: user, action: 'updated')

        expect(data[:object_kind]).to eq('work_item')
        expect(data[:event_type]).to eq('work_item')
        expect(data.dig(:object_attributes, :id)).to eq(work_item.id)
        expect(data.dig(:object_attributes, :iid)).to eq(work_item.iid)
        expect(data.dig(:object_attributes, :type)).to eq(work_item.work_item_type.name)
      end
    end

    context 'merge_request is assigned' do
      let(:merge_request) { create(:merge_request, assignees: [user], source_project: reusable_project) }
      let(:data) { described_class.new(merge_request).build(user: user, action: 'updated') }

      it 'returns correct hook data' do
        expect(data[:object_attributes]['assignee_id']).to eq(user.id)
        expect(data[:assignees].first).to eq(user.hook_attrs)
        expect(data).not_to have_key(:assignee)
      end
    end

    context 'merge_request is assigned reviewers' do
      let(:merge_request) { create(:merge_request, reviewers: [user], source_project: reusable_project) }
      let(:data) { described_class.new(merge_request).build(user: user, action: 'updated') }

      it 'returns correct hook data' do
        expect(data[:object_attributes]['reviewer_ids']).to match_array([user.id])
        expect(data[:reviewers].first).to eq(user.hook_attrs)
      end
    end

    context 'when merge_request does not have reviewers and assignees' do
      let(:merge_request) { create(:merge_request, source_project: reusable_project) }
      let(:data) { described_class.new(merge_request).build(user: user, action: 'updated') }

      it 'returns correct hook data' do
        expect(data).not_to have_key(:assignees)
        expect(data).not_to have_key(:reviewers)
      end
    end
  end
end
