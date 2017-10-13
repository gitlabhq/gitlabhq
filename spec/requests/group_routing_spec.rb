require 'spec_helper'

describe 'Deprecated boards paths' do
  it 'redirects to boards page' do
    group = create :group, name: 'gitlabhq'

    get('/groups/gitlabhq/boards')

    expect(response).to redirect_to(group_boards_path(group))
  end
end
