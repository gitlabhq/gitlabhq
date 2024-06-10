# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupIssuableAutocompleteEntity do
  let(:group) { build_stubbed(:group) }
  let(:project_namespace) { build_stubbed(:project_namespace) }
  let(:project) { build_stubbed(:project, group: group, project_namespace: project_namespace) }
  let(:issue) { build_stubbed(:issue, project: project) }

  describe '#represent' do
    subject { described_class.new(issue, parent_group: group).as_json }

    it 'includes the iid, title, and reference' do
      expect(subject).to include(:iid, :title, :reference, :icon_name)
    end
  end
end
