require 'spec_helper'

describe Gitlab::Git::GitmodulesParser do
  it 'should parse a .gitmodules file correctly' do
    parser = described_class.new(<<-'GITMODULES'.strip_heredoc)
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

    modules = parser.parse

    expect(modules).to eq({
                            'vendor/libgit2' => { 'name' => 'vendor/libgit2',
                                                  'url' => 'https://github.com/nodegit/libgit2.git' },
                            'new/path' => { 'name' => 'moved',
                                            'url' => 'https://example.com/some/project' }
                          })
  end
end
