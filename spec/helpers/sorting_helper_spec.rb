require 'spec_helper'

describe SortingHelper do

  describe 'link_to_sort' do
    it 'it returns a simple link tag when sort is not the current one' do
      stub_url_for('sort', 'bar')
      expect(helper.link_to_sort('Foo', 'bar', 'baz')).to eq <<-LINK.strip_heredoc.strip
      <a href="/dashboard/projects?sort=bar">Foo</a>
      LINK
    end

    it 'it returns an active link tag when sort is the current one' do
      stub_url_for('sort', 'bar')
      expect(helper.link_to_sort('Foo', 'bar', 'bar')).to eq <<-LINK.strip_heredoc.strip
      <a class="active" href="/dashboard/projects?sort=bar"><span><i class="fa fa-check"></i><strong class="item-title">Foo</strong></span></a>
      LINK
    end
  end

  describe 'link_to_filter' do
    it 'it returns a simple link tag when sort is not the current one' do
      stub_url_for('sort', 'bar')
      expect(helper.link_to_filter('Foo', 'bar', 'baz')).to eq <<-LINK.strip_heredoc.strip
      <a href="/dashboard/projects?sort=bar">Foo</a>
      LINK
    end

    it 'it returns an active link tag when sort is the current one' do
      stub_url_for('sort', 'bar')
      expect(helper.link_to_filter('Foo', 'bar', 'bar')).to eq <<-LINK.strip_heredoc.strip
      <a class="active" href="/dashboard/projects?sort=bar"><span><i class="fa fa-check"></i><strong class="item-title">Foo</strong></span></a>
      LINK
    end
  end

  private

  def stub_url_for(key, value)
    url = "/dashboard/projects"
    url << "?#{key}=#{value}"
    allow(helper).to receive(:url_for).and_return(url)
  end

end
