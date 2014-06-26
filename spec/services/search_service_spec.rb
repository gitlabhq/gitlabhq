require 'spec_helper'

describe 'Search::GlobalService' do
  let(:user) { create(:user) }
  let(:public_user) { create(:user) }
  let(:internal_user) { create(:user) }

  let!(:found_project)    { create(:empty_project, :private, name: 'searchable_project') }
  let!(:unfound_project)  { create(:empty_project, :private, name: 'unfound_project') }
  let!(:internal_project) { create(:empty_project, :internal, name: 'searchable_internal_project') }
  let!(:public_project)   { create(:empty_project, :public, name: 'searchable_public_project') }

  before do
    found_project.team << [user, :master]
  end

  describe '#execute' do
    context 'unauthenticated' do
      it 'should return public projects only' do
        context = Search::GlobalService.new(nil, search: "searchable")
        results = context.execute
        results[:projects].should match_array [public_project]
      end
    end

    context 'authenticated' do
      it 'should return public, internal and private projects' do
        context = Search::GlobalService.new(user, search: "searchable")
        results = context.execute
        results[:projects].should match_array [public_project, found_project, internal_project]
      end

      it 'should return only public & internal projects' do
        context = Search::GlobalService.new(internal_user, search: "searchable")
        results = context.execute
        results[:projects].should match_array [internal_project, public_project]
      end

      it 'namespace name should be searchable' do
        context = Search::GlobalService.new(user, search: found_project.namespace.path)
        results = context.execute
        results[:projects].should match_array [found_project]
      end
    end
  end
end
