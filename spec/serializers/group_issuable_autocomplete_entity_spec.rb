# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupIssuableAutocompleteEntity do
  let(:group) { build_stubbed(:group) }
  let(:project) { build_stubbed(:project, group: group) }
  let(:issue) { build_stubbed(:issue, project: project) }

  describe '#represent' do
    subject { described_class.new(issue, parent_group: group).as_json }

    it 'includes the iid, title, and reference' do
      expect(subject).to include(:iid, :title, :reference)
    end
  end
end
