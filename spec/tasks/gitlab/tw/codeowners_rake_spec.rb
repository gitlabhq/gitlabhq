# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'tw:codeowners', :silence_stdout, feature_category: :gitlab_docs do
  before do
    Rake.application.rake_require 'tasks/gitlab/tw/codeowners'
  end

  it 'updates the codeowners file' do
    stub_files({
      '/test/file1.md' => { 'group' => 'Group 1' },
      '/test/file2.md' => { 'group' => 'Group 2' },
      '/test/file3.md' => { 'group' => 'Group 1' },
      '/test/nested/file4.md' => { 'group' => 'Group 1' }
    })
    stub_group_assignments([
      TwCodeowners::CodeOwnerRule.new('Group 1', '@writer1'),
      TwCodeowners::CodeOwnerRule.new('Group 2', '@writer2')
    ])

    expect_codeowners(<<~PREVIOUS, <<~EXPECTED)
      [Documentation Pages]
      # Begin rake-managed-docs-block
      /not_existing_file.md
      # End rake-managed-docs-block
    PREVIOUS
      [Documentation Pages]
      # Begin rake-managed-docs-block
      /test/ @writer1
      /test/file2.md @writer2
      # End rake-managed-docs-block
    EXPECTED

    expect { run_rake_task('tw:codeowners') }.to output("✓ CODEOWNERS updated\n").to_stdout
  end

  it 'supports procs to determine the owner' do
    stub_files({
      '/test/file1.md' => { 'group' => 'Group 1' },
      '/test/nested/file2.md' => { 'group' => 'Group 1' }
    })
    stub_group_assignments([
      TwCodeowners::CodeOwnerRule.new('Group 1', ->(path) {
        path.starts_with?('/test/nested') ? '@writer1' : '@writer2'
      })
    ])

    expect_codeowners(<<~PREVIOUS, <<~EXPECTED)
      [Documentation Pages]
      # Begin rake-managed-docs-block
      /not_existing_file.md
      # End rake-managed-docs-block
    PREVIOUS
      [Documentation Pages]
      # Begin rake-managed-docs-block
      /test/ @writer2
      /test/nested/ @writer1
      # End rake-managed-docs-block
    EXPECTED

    expect { run_rake_task('tw:codeowners') }.to output("✓ CODEOWNERS updated\n").to_stdout
  end

  it 'outputs if codeowners are already up to date' do
    stub_files({})

    expect_codeowners(<<~PREVIOUS, <<~EXPECTED)
      [Documentation Pages]
      # Begin rake-managed-docs-block

      # End rake-managed-docs-block
    PREVIOUS
      [Documentation Pages]
      # Begin rake-managed-docs-block

      # End rake-managed-docs-block
    EXPECTED

    expect { run_rake_task('tw:codeowners') }.to output("~ CODEOWNERS already up to date\n").to_stdout
  end

  it 'mentions files with missing metadata' do
    stub_files({ 'file1.md' => {} })

    expect_codeowners(<<~PREVIOUS, <<~EXPECTED)
      [Documentation Pages]
      # Begin rake-managed-docs-block

      # End rake-managed-docs-block
    PREVIOUS
      [Documentation Pages]
      # Begin rake-managed-docs-block

      # End rake-managed-docs-block
    EXPECTED

    expect do
      run_rake_task('tw:codeowners')
    end.to output("~ CODEOWNERS already up to date\n\n✘ Files with missing metadata found:\nfile1.md\n").to_stdout
  end

  def stub_files(files)
    allow(Dir).to receive(:glob).and_call_original
    glob_stubber = allow(Dir).to receive(:glob).with(Rails.root.join('doc/**/*.md'))
    files.each do |path, metadata|
      glob_stubber = glob_stubber.and_yield(path)
      allow(YAML).to receive(:load_file).with(path).and_return(metadata)
    end
  end

  def stub_group_assignments(group_assignments)
    stub_const('TwCodeowners::CODE_OWNER_RULES', group_assignments)
  end

  def expect_codeowners(previous_content, expected_content)
    codeowners_path = Rails.root.join('.gitlab/CODEOWNERS')
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(codeowners_path).and_return(previous_content)

    expect(File).to receive(:write).with(codeowners_path, expected_content)
  end
end
