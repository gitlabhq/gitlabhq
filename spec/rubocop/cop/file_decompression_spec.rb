# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/file_decompression'

RSpec.describe RuboCop::Cop::FileDecompression do
  it 'does not flag when using a system command not related to file decompression' do
    expect_no_offenses('system("ls")')
  end

  described_class::FORBIDDEN_COMMANDS.map { [_1, '^' * _1.length] }.each do |cmd, len|
    it "flags the when using '#{cmd}' system command" do
      expect_offense(<<~RUBY)
      system('#{cmd}')
      ^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY

      expect_offense(<<~RUBY)
      exec('#{cmd}')
      ^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY

      expect_offense(<<~RUBY)
      Kernel.spawn('#{cmd}')
      ^^^^^^^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY

      expect_offense(<<~RUBY)
      IO.popen('#{cmd}')
      ^^^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY
    end

    it "flags the when using '#{cmd}' subshell command" do
      expect_offense(<<~RUBY)
      `#{cmd}`
      ^#{len}^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY

      expect_offense(<<~RUBY)
      %x(#{cmd})
      ^^^#{len}^ While extracting files check for symlink to avoid arbitrary file reading[...]
      RUBY
    end
  end
end
