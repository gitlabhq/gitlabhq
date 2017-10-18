require 'spec_helper'

describe 'Group routing' do
  describe 'subgroup "boards"' do
    it 'shows group show page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq/boards', any_args).and_return(true)

      expect(get('/groups/gitlabhq/boards')).to route_to('groups#show', id: 'gitlabhq/boards')
    end

    it 'shows boards index page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
    end
  end
end
