# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TabHelper do
  include ApplicationHelper

  describe 'nav_link' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(controller).to receive(:controller_name).and_return('foo')
      allow(self).to receive(:action_name).and_return('foo')
    end

    context 'with the content of the li' do
      it 'captures block output' do
        expect(nav_link { "Testing Blocks" }).to match(/Testing Blocks/)
      end
    end

    it 'passes extra html options to the list element' do
      expect(nav_link(action: :foo, html_options: { class: 'home' })).to match(/<li class="home active">/)
      expect(nav_link(html_options: { class: 'active' })).to match(/<li class="active">/)
    end

    where(:controller_param, :action_param, :path_param, :active) do
      nil          | nil          | nil                    | false
      :foo         | nil          | nil                    | true
      :bar         | nil          | nil                    | false
      :bar         | :foo         | nil                    | false
      :foo         | :bar         | nil                    | false
      :foo         | :foo         | nil                    | true
      :bar         | nil          | 'foo#foo'              | true
      :bar         | nil          | ['foo#foo', 'bar#bar'] | true
      :bar         | :bar         | ['foo#foo', 'bar#bar'] | true
      :foo         | nil          | 'bar#foo'              | true
      :bar         | nil          | 'bar#foo'              | false
      :foo         | [:foo, :bar] | 'bar#foo'              | true
      :bar         | :bar         | 'foo#foo'              | true
      :foo         | :foo         | 'bar#foo'              | true
      :bar         | :foo         | 'bar#foo'              | false
      :foo         | :bar         | 'bar#foo'              | false
      [:foo, :bar] | nil          | nil                    | true
      [:foo, :bar] | nil          | 'bar#foo'              | true
      [:foo, :bar] | :foo         | 'bar#foo'              | true
      nil          | :foo         | nil                    | true
      nil          | :bar         | nil                    | false
      nil          | nil          | 'foo#bar'              | false
      nil          | nil          | 'foo#foo'              | true
      nil          | :bar         | ['foo#foo', 'bar#bar'] | true
      nil          | :bar         | 'foo#foo'              | true
      nil          | :foo         | 'bar#foo'              | true
      nil          | [:foo, :bar] | nil                    | true
      nil          | [:foo, :bar] | 'bar#foo'              | true
      nil          | :bar         | 'bar#foo'              | false
    end

    with_them do
      specify do
        result = nav_link(controller: controller_param, action: action_param, path: path_param)

        if active
          expect(result).to match(/active/)
        else
          expect(result).not_to match(/active/)
        end
      end
    end

    context 'with namespace in path notation' do
      before do
        allow(controller).to receive(:controller_path).and_return('bar/foo')
      end

      where(:controller_param, :action_param, :path_param, :active) do
        'foo/foo' | nil  | nil           | false
        'bar/foo' | nil  | nil           | true
        'foo/foo' | :foo | nil           | false
        'bar/foo' | :bar | nil           | false
        'bar/foo' | :foo | nil           | true
        nil       | nil  | 'foo/foo#foo' | false
        nil       | nil  | 'bar/foo#foo' | true
      end

      with_them do
        specify do
          result = nav_link(controller: controller_param, action: action_param, path: path_param)

          if active
            expect(result).to match(/active/)
          else
            expect(result).not_to match(/active/)
          end
        end
      end
    end
  end
end
