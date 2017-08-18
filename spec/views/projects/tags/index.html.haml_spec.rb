require 'spec_helper'

describe 'projects/tags/index' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    assign(:tags, [])

    allow(view).to receive(:current_ref).and_return('master')
    allow(view).to receive(:can?).and_return(false)
  end

  it 'defaults sort dropdown toggle to last updated' do
    render

    expect(rendered).to have_button('Last updated')
  end
end
