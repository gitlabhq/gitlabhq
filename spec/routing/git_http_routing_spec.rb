# frozen_string_literal: true

require 'spec_helper'

describe 'git_http routing' do
  include RSpec::Rails::RequestExampleGroup

  describe 'wiki.git routing', 'routing' do
    let(:wiki_path)  { '/gitlab/gitlabhq/wikis' }

    it 'redirects namespace/project.wiki.git to the project wiki' do
      expect(get('/gitlab/gitlabhq.wiki.git')).to redirect_to(wiki_path)
    end

    it 'preserves query parameters' do
      expect(get('/gitlab/gitlabhq.wiki.git?foo=bar&baz=qux')).to redirect_to("#{wiki_path}?foo=bar&baz=qux")
    end

    it 'only redirects when the format is .git' do
      expect(get('/gitlab/gitlabhq.wiki')).not_to redirect_to(wiki_path)
      expect(get('/gitlab/gitlabhq.wiki.json')).not_to redirect_to(wiki_path)
    end
  end
end
