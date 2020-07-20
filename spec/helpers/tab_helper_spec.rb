# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TabHelper do
  include ApplicationHelper

  describe 'nav_link' do
    before do
      allow(controller).to receive(:controller_name).and_return('foo')
      allow(self).to receive(:action_name).and_return('foo')
    end

    context 'with the content of the li' do
      it "captures block output" do
        expect(nav_link { "Testing Blocks" }).to match(/Testing Blocks/)
      end
    end

    context 'with controller param' do
      it "performs checks on the current controller" do
        expect(nav_link(controller: :foo)).to match(/<li class="active">/)
        expect(nav_link(controller: :bar)).not_to match(/active/)
        expect(nav_link(controller: [:foo, :bar])).to match(/active/)
      end

      context 'with action param' do
        it "performs checks on both controller and action when both are present" do
          expect(nav_link(controller: :bar, action: :foo)).not_to match(/active/)
          expect(nav_link(controller: :foo, action: :bar)).not_to match(/active/)
          expect(nav_link(controller: :foo, action: :foo)).to match(/active/)
        end
      end

      context 'with namespace in path notation' do
        before do
          allow(controller).to receive(:controller_path).and_return('bar/foo')
        end

        it 'performs checks on both controller and namespace' do
          expect(nav_link(controller: 'foo/foo')).not_to match(/active/)
          expect(nav_link(controller: 'bar/foo')).to match(/active/)
        end

        context 'with action param' do
          it "performs checks on both namespace, controller and action when they are all present" do
            expect(nav_link(controller: 'foo/foo', action: :foo)).not_to match(/active/)
            expect(nav_link(controller: 'bar/foo', action: :bar)).not_to match(/active/)
            expect(nav_link(controller: 'bar/foo', action: :foo)).to match(/active/)
          end
        end
      end
    end

    context 'with action param' do
      it "performs checks on the current action" do
        expect(nav_link(action: :foo)).to match(/<li class="active">/)
        expect(nav_link(action: :bar)).not_to match(/active/)
        expect(nav_link(action: [:foo, :bar])).to match(/active/)
      end
    end

    context 'with path param' do
      it "accepts a path shorthand" do
        expect(nav_link(path: 'foo#bar')).not_to match(/active/)
        expect(nav_link(path: 'foo#foo')).to match(/active/)
      end

      context 'with namespace' do
        before do
          allow(controller).to receive(:controller_path).and_return('bar/foo')
        end

        it 'accepts a path shorthand with namespace' do
          expect(nav_link(path: 'bar/foo#foo')).to match(/active/)
          expect(nav_link(path: 'foo/foo#foo')).not_to match(/active/)
        end
      end
    end

    it "passes extra html options to the list element" do
      expect(nav_link(action: :foo, html_options: { class: 'home' })).to match(/<li class="home active">/)
      expect(nav_link(html_options: { class: 'active' })).to match(/<li class="active">/)
    end
  end
end
