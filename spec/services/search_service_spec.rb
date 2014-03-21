require 'spec_helper'

describe 'Search::GlobalService' do
  let(:user) { create(:user, namespace: found_namespace) }
  let(:public_user) { create(:user, namespace: public_namespace) }
  let(:internal_user) { create(:user, namespace: internal_namespace) }

  let(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let(:internal_namespace) { create(:namespace, name: 'searchable internal namespace', path: 'something_internal') }
  let(:public_namespace) { create(:namespace, name: 'searchable public namespace', path: 'something_public') }

  let!(:found_project) { create(:project, :private, name: 'searchable_project', creator_id: user.id, namespace: found_namespace) }
  let!(:unfound_project) { create(:project, :private, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace) }
  let!(:internal_project) { create(:project, :internal, name: 'searchable_internal_project', creator_id: internal_user.id, namespace: internal_namespace) }
  let!(:public_project) { create(:project, :public, name: 'searchable_public_project', creator_id: public_user.id, namespace: public_namespace) }

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
        context = Search::GlobalService.new(user, search: "searchable namespace")
        results = context.execute
        results[:projects].should match_array [found_project]
      end
    end
  end
end
