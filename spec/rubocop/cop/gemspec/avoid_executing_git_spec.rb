# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gemspec/avoid_executing_git'

RSpec.describe RuboCop::Cop::Gemspec::AvoidExecutingGit do
  it 'flags violation for executing git' do
    expect_offense(<<~RUBY)
      Gem::Specification.new do |gem|
        gem.executable    = `git ls-files -- bin/*`.split("\\n").map{ |f| File.basename(f) }
                            ^^^^^^^^^^^^^^^^^^^^^^^ Do not execute `git` in gemspec.
        gem.files         = `git ls-files`.split("\\n")
                            ^^^^^^^^^^^^^^ Do not execute `git` in gemspec.
        gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\\n")
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not execute `git` in gemspec.
      end
    RUBY
  end

  it 'does not flag violation for using a glob' do
    expect_no_offenses(<<~RUBY)
      Gem::Specification.new do |gem|
        gem.files = Dir.glob("lib/**/*.*")
        gem.test_files = Dir.glob("spec/**/**/*.*")
      end
    RUBY
  end
end
