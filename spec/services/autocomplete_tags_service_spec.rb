require 'rails_helper'

RSpec.describe AutocompleteTagsService do
  describe '#run' do
    it 'returns a hash of all tags' do
      create(:ci_runner, tag_list: %w[tag1 tag2])
      create(:ci_runner, tag_list: %w[tag1 tag3])
      create(:project, tag_list: %w[tag4])

      expect(described_class.new(Ci::Runner).run).to match_array [
        { id: kind_of(Integer), title: 'tag1' },
        { id: kind_of(Integer), title: 'tag2' },
        { id: kind_of(Integer), title: 'tag3' }
      ]
    end
  end
end
