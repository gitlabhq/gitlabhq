# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'help/drawers' do
  describe 'Markdown rendering' do
    before do
      allow(view).to receive(:get_markdown_without_frontmatter).and_return('[GitLab](https://about.gitlab.com/)')
      assign(:clean_path, 'user/ssh')
    end

    it 'renders Markdown' do
      render

      expect(rendered).to have_link('GitLab', href: 'https://about.gitlab.com/')
    end
  end
end
