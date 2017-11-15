require 'spec_helper'

describe Gitlab::HookData::IssuableBuilder do
  set(:user) { create(:user) }

  # This shared example requires a `builder` and `user` variable
  shared_examples 'issuable hook data' do |kind|
    let(:data) { builder.build(user: user) }

    include_examples 'project hook data' do
      let(:project) { builder.issuable.project }
    end
    include_examples 'deprecated repository hook data'

    context "with a #{kind}" do
      it 'contains issuable data' do
        expect(data[:object_kind]).to eq(kind)
        expect(data[:user]).to eq(user.hook_attrs)
        expect(data[:project]).to eq(builder.issuable.project.hook_attrs)
        expect(data[:object_attributes]).to eq(builder.issuable.hook_attrs)
        expect(data[:changes]).to eq({})
        expect(data[:repository]).to eq(builder.issuable.project.hook_attrs.slice(:name, :url, :description, :homepage))
      end

      it 'does not contain certain keys' do
        expect(data).not_to have_key(:assignees)
        expect(data).not_to have_key(:assignee)
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
            total_time_spent: [1, 2]
          }
        end
        let(:data) { builder.build(user: user, changes: changes) }

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
    it_behaves_like 'issuable hook data', 'issue' do
      let(:issuable) { create(:issue, description: 'A description') }
      let(:builder) { described_class.new(issuable) }
    end

    it_behaves_like 'issuable hook data', 'merge_request' do
      let(:issuable) { create(:merge_request, description: 'A description') }
      let(:builder) { described_class.new(issuable) }
    end

    context 'issue is assigned' do
      let(:issue) { create(:issue, assignees: [user]) }
      let(:data) { described_class.new(issue).build(user: user) }

      it 'returns correct hook data' do
        expect(data[:object_attributes]['assignee_id']).to eq(user.id)
        expect(data[:assignees].first).to eq(user.hook_attrs)
        expect(data).not_to have_key(:assignee)
      end
    end

    context 'merge_request is assigned' do
      let(:merge_request) { create(:merge_request, assignee: user) }
      let(:data) { described_class.new(merge_request).build(user: user) }

      it 'returns correct hook data' do
        expect(data[:object_attributes]['assignee_id']).to eq(user.id)
        expect(data[:assignee]).to eq(user.hook_attrs)
        expect(data).not_to have_key(:assignees)
      end
    end
  end
end
