# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::IssuableSerializer, feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }
  let_it_be(:group) { build(:group) }
  let_it_be(:project) { build(:project, group: group) }
  let_it_be(:issue) { build(:issue, project: project, title: 'Test Issue') }

  let(:serializer) { described_class.new }

  describe '#represent' do
    it 'serializes an issue correctly' do
      result = serializer.represent(issue)

      expect(result.as_json).to include(
        'iid' => issue.iid,
        'title' => issue.title,
        'reference' => issue.to_reference
      )
    end
  end
end
