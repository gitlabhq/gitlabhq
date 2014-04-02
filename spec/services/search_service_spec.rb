require 'spec_helper'

describe 'Search::GlobalService' do
  let(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let(:user) { create(:user, namespace: found_namespace) }
  let!(:found_project) { create(:project, name: 'searchable_project', creator_id: user.id, namespace: found_namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

  let(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let!(:unfound_project) { create(:project, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

  let(:internal_namespace) { create(:namespace, path: 'something_internal',name: 'searchable internal namespace') }
  let(:internal_user) { create(:user, namespace: internal_namespace) }
  let!(:internal_project) { create(:project, name: 'searchable_internal_project', creator_id: internal_user.id, namespace: internal_namespace, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

  let(:public_namespace) { create(:namespace, path: 'something_public',name: 'searchable public namespace') }
  let(:public_user) { create(:user, namespace: public_namespace) }
  let!(:public_project) { create(:project, name: 'searchable_public_project', creator_id: public_user.id, namespace: public_namespace, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  describe '#execute' do
    context 'unauthenticated' do
      it 'should return public projects only' do
        context = Search::GlobalService.new(nil, search: "searchable")
        results = context.execute
        results[:projects].should have(1).items
        results[:projects].should include(public_project)
      end
    end

    context 'authenticated' do
      it 'should return public, internal and private projects' do
        context = Search::GlobalService.new(user, search: "searchable")
        results = context.execute
        results[:projects].should have(3).items
        results[:projects].should include(public_project)
        results[:projects].should include(found_project)
        results[:projects].should include(internal_project)
      end

      it 'should return only public & internal projects' do
        context = Search::GlobalService.new(internal_user, search: "searchable")
        results = context.execute
        results[:projects].should have(2).items
        results[:projects].should include(internal_project)
        results[:projects].should include(public_project)
      end

      it 'namespace name should be searchable' do
        context = Search::GlobalService.new(user, search: "searchable namespace")
        results = context.execute
        results[:projects].should == [found_project]
      end
    end
  end
end
