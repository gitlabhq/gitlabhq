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
          title_html: %w[foo bar]
        }
      end
      let(:data) { builder.build(user: user, changes: changes) }

      it 'populates the :changes hash' do
        expect(data[:changes]).to match(hash_including({
          title: { previous: 'A title', current: 'Hello World' },
          description: { previous: 'A description', current: 'A cool description' }
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
