require 'spec_helper'

describe TabHelper do
  include ApplicationHelper

  describe 'nav_link' do
    before do
      controller.stub(:controller_name).and_return('foo')
      allow(self).to receive(:action_name).and_return('foo')
    end

    it "captures block output" do
      nav_link { "Testing Blocks" }.should match(/Testing Blocks/)
    end

    it "performs checks on the current controller" do
      nav_link(controller: :foo).should match(/<li class="active">/)
      nav_link(controller: :bar).should_not match(/active/)
      nav_link(controller: [:foo, :bar]).should match(/active/)
    end

    it "performs checks on the current action" do
      nav_link(action: :foo).should match(/<li class="active">/)
      nav_link(action: :bar).should_not match(/active/)
      nav_link(action: [:foo, :bar]).should match(/active/)
    end

    it "performs checks on both controller and action when both are present" do
      nav_link(controller: :bar, action: :foo).should_not match(/active/)
      nav_link(controller: :foo, action: :bar).should_not match(/active/)
      nav_link(controller: :foo, action: :foo).should match(/active/)
    end

    it "accepts a path shorthand" do
      nav_link(path: 'foo#bar').should_not match(/active/)
      nav_link(path: 'foo#foo').should match(/active/)
    end

    it "passes extra html options to the list element" do
      nav_link(action: :foo, html_options: {class: 'home'}).should match(/<li class="home active">/)
      nav_link(html_options: {class: 'active'}).should match(/<li class="active">/)
    end
  end
end
