# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::GitmodulesParser do
  it 'parses a .gitmodules file correctly' do
    data = <<~GITMODULES
      [submodule "vendor/libgit2"]
         path = vendor/libgit2
      [submodule "vendor/libgit2"]
         url = https://github.com/nodegit/libgit2.git

      # a comment
      [submodule "moved"]
          path = new/path
          url = https://example.com/some/project
      [submodule "bogus"]
          url = https://example.com/another/project
    GITMODULES

    parser = described_class.new(data.gsub("\n", "\r\n"))
    modules = parser.parse

    expect(modules).to eq({
                            'vendor/libgit2' => { 'name' => 'vendor/libgit2',
                                                  'url' => 'https://github.com/nodegit/libgit2.git' },
                            'new/path' => { 'name' => 'moved',
                                            'url' => 'https://example.com/some/project' }
                          })
  end
end
