# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/file_decompression'

RSpec.describe RuboCop::Cop::FileDecompression do
  it 'does not flag when using a system command not related to file decompression' do
    expect_no_offenses('system("ls")')
  end

  described_class::FORBIDDEN_COMMANDS.map { [_1, '^' * _1.length] }.each do |cmd, len|
    it "flags the when using '#{cmd}' system command" do
      expect_offense(<<~SOURCE)
      system('#{cmd}')
      ^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE

      expect_offense(<<~SOURCE)
      exec('#{cmd}')
      ^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE

      expect_offense(<<~SOURCE)
      Kernel.spawn('#{cmd}')
      ^^^^^^^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE

      expect_offense(<<~SOURCE)
      IO.popen('#{cmd}')
      ^^^^^^^^^^#{len}^^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE
    end

    it "flags the when using '#{cmd}' subshell command" do
      expect_offense(<<~SOURCE)
      `#{cmd}`
      ^#{len}^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE

      expect_offense(<<~SOURCE)
      %x(#{cmd})
      ^^^#{len}^ While extracting files check for symlink to avoid arbitrary file reading[...]
      SOURCE
    end
  end
end
