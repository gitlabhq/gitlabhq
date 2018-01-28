require 'spec_helper'

describe Search::GlobalService do
  let(:user) { create(:user) }
  let(:internal_user) { create(:user) }

  let!(:found_project)    { create(:project, :private, name: 'searchable_project') }
  let!(:unfound_project)  { create(:project, :private, name: 'unfound_project') }
  let!(:internal_project) { create(:project, :internal, name: 'searchable_internal_project') }
  let!(:public_project)   { create(:project, :public, name: 'searchable_public_project') }

  before do
    found_project.add_master(user)
  end

  describe '#execute' do
    context 'unauthenticated' do
      it 'returns public projects only' do
        results = described_class.new(nil, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project]
      end
    end

    context 'authenticated' do
      it 'returns public, internal and private projects' do
        results = described_class.new(user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project, found_project, internal_project]
      end

      it 'returns only public & internal projects' do
        results = described_class.new(internal_user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [internal_project, public_project]
      end

      it 'project name is searchable' do
        results = described_class.new(user, search: found_project.name).execute

        expect(results.objects('projects')).to match_array [found_project]
      end
    end
  end
end
