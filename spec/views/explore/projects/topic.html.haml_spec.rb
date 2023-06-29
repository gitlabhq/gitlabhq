# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/projects/topic.html.haml', feature_category: :groups_and_projects do
  let(:topic) { build_stubbed(:topic, name: 'test-topic', title: 'Test topic') }
  let(:project) { build_stubbed(:project, :public, topic_list: topic.name) }

  before do
    assign(:topic, topic)
    assign(:projects, [project])

    controller.params[:controller] = 'explore/projects'
    controller.params[:action] = 'topic'

    allow(view).to receive(:current_user).and_return(nil)

    render
  end

  it 'renders atom feed button with matching path' do
    expect(rendered).to have_link(href: topic_explore_projects_path(topic.name, format: 'atom'))
  end
end
