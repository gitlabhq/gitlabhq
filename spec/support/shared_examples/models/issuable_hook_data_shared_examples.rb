# This shared example requires a `user` variable
shared_examples 'issuable hook data' do |kind|
  let(:data) { issuable.to_hook_data(user) }

  include_examples 'project hook data' do
    let(:project) { issuable.project }
  end
  include_examples 'deprecated repository hook data'

  context "with a #{kind}" do
    it 'contains issuable data' do
      expect(data[:object_kind]).to eq(kind)
      expect(data[:user]).to eq(user.hook_attrs)
      expect(data[:object_attributes]).to eq(issuable.hook_attrs)
      expect(data[:changes]).to match(hash_including({
        'author_id' => [nil, issuable.author_id],
        'cached_markdown_version' => [nil, issuable.cached_markdown_version],
        'created_at' => [nil, a_kind_of(ActiveSupport::TimeWithZone)],
        'description' => [nil, issuable.description],
        'description_html' => [nil, issuable.description_html],
        'id' => [nil, issuable.id],
        'iid' => [nil, issuable.iid],
        'state' => [nil, issuable.state],
        'title' => [nil, issuable.title],
        'title_html' => [nil, issuable.title_html],
        'updated_at' => [nil, a_kind_of(ActiveSupport::TimeWithZone)]
      }))
      expect(data).not_to have_key(:assignee)
    end

    describe 'simple attributes are updated' do
      before do
        issuable.update(title: 'Hello World', description: 'A cool description')
      end

      it 'includes an empty :changes hash' do
        expect(data[:changes]).to match(hash_including({
          'title' => [issuable.previous_changes['title'][0], 'Hello World'],
          'description' => [issuable.previous_changes['description'][0], 'A cool description'],
          'updated_at' => [a_kind_of(ActiveSupport::TimeWithZone), a_kind_of(ActiveSupport::TimeWithZone)]
        }))
      end
    end

    context "#{kind} has labels" do
      let(:labels) { [create(:label), create(:label)] }

      before do
        issuable.update_attribute(:labels, labels)
      end

      it 'includes labels in the hook data' do
        expect(data[:labels]).to eq(labels.map(&:hook_attrs))
        expect(data[:changes]).to eq({ 'labels' => [[], labels.map(&:name)] })
      end
    end
  end
end
