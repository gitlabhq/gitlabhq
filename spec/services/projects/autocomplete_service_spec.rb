require 'spec_helper'

describe Projects::AutocompleteService, services: true do
  let(:project) { create(:empty_project, :public) }

  subject(:autocomplete) { described_class.new(project) }

  describe '#issues' do
    it 'should not list confidential issues' do
      issue = create(:issue, project: project)
      create(:issue, :confidential, project: project)

      expect(autocomplete.issues.map(&:iid)).to eq [issue.iid]
    end
  end
end
