require 'spec_helper'

describe 'layouts/nav/sidebar/_admin' do
  shared_examples 'page has active tab' do |title|
    it "activates #{title} tab" do
      render

      expect(rendered).to have_selector('.nav-sidebar .sidebar-top-level-items > li.active', count: 1)
      expect(rendered).to have_css('.nav-sidebar .sidebar-top-level-items > li.active', text: title)
    end
  end

  shared_examples 'page has active sub tab' do |title|
    it "activates #{title} sub tab" do
      render

      expect(rendered).to have_css('.sidebar-sub-level-items > li.active', text: title)
    end
  end

  context 'on home page' do
    before do
      allow(controller).to receive(:controller_name).and_return('dashboard')
    end

    it_behaves_like 'page has active tab', 'Overview'
  end

  it_behaves_like 'has nav sidebar'

  context 'on projects' do
    before do
      allow(controller).to receive(:controller_name).and_return('projects')
      allow(controller).to receive(:controller_path).and_return('admin/projects')
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Projects'
  end

  context 'on groups' do
    before do
      allow(controller).to receive(:controller_name).and_return('groups')
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Groups'
  end

  context 'on users' do
    before do
      allow(controller).to receive(:controller_name).and_return('users')
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Users'
  end

  context 'on logs' do
    before do
      allow(controller).to receive(:controller_name).and_return('logs')
    end

    it_behaves_like 'page has active tab', 'Monitoring'
    it_behaves_like 'page has active sub tab', 'Logs'
  end

  context 'on messages' do
    before do
      allow(controller).to receive(:controller_name).and_return('broadcast_messages')
    end

    it_behaves_like 'page has active tab', 'Messages'
  end

  context 'on hooks' do
    before do
      allow(controller).to receive(:controller_name).and_return('hooks')
    end

    it_behaves_like 'page has active tab', 'Hooks'
  end

  context 'on background jobs' do
    before do
      allow(controller).to receive(:controller_name).and_return('background_jobs')
    end

    it_behaves_like 'page has active tab', 'Monitoring'
    it_behaves_like 'page has active sub tab', 'Background Jobs'
  end
end
