# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Conflict::File do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:their_commit) { TestEnv::BRANCH_SHA['conflict-start'] }
  let(:our_commit) { TestEnv::BRANCH_SHA['conflict-resolvable'] }
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project) }
  let(:conflicts_client) { repository.gitaly_conflicts_client(our_commit, their_commit) }
  let(:raw_conflict_files) { conflicts_client.list_conflict_files }
  let(:conflict_file_name) { 'files/ruby/regex.rb' }
  let(:raw_conflict_file) { raw_conflict_files.find { |conflict| conflict.our_path == conflict_file_name } }
  let(:conflict_file) { described_class.new(raw_conflict_file, merge_request: merge_request) }

  describe 'delegates' do
    it { expect(conflict_file).to delegate_method(:type).to(:raw) }
    it { expect(conflict_file).to delegate_method(:content).to(:raw) }
    it { expect(conflict_file).to delegate_method(:path).to(:raw) }
    it { expect(conflict_file).to delegate_method(:ancestor_path).to(:raw) }
    it { expect(conflict_file).to delegate_method(:their_path).to(:raw) }
    it { expect(conflict_file).to delegate_method(:our_path).to(:raw) }
    it { expect(conflict_file).to delegate_method(:our_mode).to(:raw) }
    it { expect(conflict_file).to delegate_method(:our_blob).to(:raw) }
    it { expect(conflict_file).to delegate_method(:repository).to(:raw) }
  end

  describe '#resolve_lines' do
    let(:section_keys) { conflict_file.sections.map { |section| section[:id] }.compact }

    context 'when resolving everything to the same side' do
      let(:resolution_hash) { section_keys.index_with { 'head' } }
      let(:resolved_lines) { conflict_file.resolve_lines(resolution_hash) }
      let(:expected_lines) { conflict_file.lines.reject { |line| line.type == 'old' } }

      it 'has the correct number of lines' do
        expect(resolved_lines.length).to eq(expected_lines.length)
      end

      it 'has content matching the chosen lines' do
        expect(resolved_lines.map(&:text)).to eq(expected_lines.map(&:text))
      end
    end

    context 'with mixed resolutions' do
      let(:resolution_hash) do
        section_keys.map.with_index { |key, i| [key, i.even? ? 'head' : 'origin'] }.to_h
      end

      let(:resolved_lines) { conflict_file.resolve_lines(resolution_hash) }

      it 'has the correct number of lines' do
        file_lines = conflict_file.lines.reject { |line| line.type == 'new' }

        expect(resolved_lines.length).to eq(file_lines.length)
      end

      it 'returns a file containing only the chosen parts of the resolved sections' do
        expect(resolved_lines.chunk { |line| line.type || 'both' }.map(&:first))
          .to eq(%w[both new both old both new both])
      end
    end

    it 'raises ResolutionError when passed a hash without resolutions for all sections' do
      empty_hash = section_keys.index_with { nil }
      invalid_hash = section_keys.index_with { 'invalid' }

      expect { conflict_file.resolve_lines({}) }
        .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)

      expect { conflict_file.resolve_lines(empty_hash) }
        .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)

      expect { conflict_file.resolve_lines(invalid_hash) }
        .to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)
    end
  end

  describe '#highlight_lines!' do
    def html_to_text(html)
      CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(html)).delete("\n")
    end

    it 'is called implicitly when rich_text is accessed on a line' do
      expect(conflict_file).to receive(:highlight_lines!).once.and_call_original

      conflict_file.lines.each(&:rich_text)
    end

    it 'sets the rich_text of the lines matching the text content' do
      conflict_file.lines.each do |line|
        expect(line.text).to eq(html_to_text(line.rich_text))
      end
    end

    # This spec will break if Rouge's highlighting changes, but we need to
    # ensure that the lines are actually highlighted.
    it 'highlights the lines correctly' do
      expect(conflict_file.lines.first.rich_text)
        .to eq("<span id=\"LC1\" class=\"line\" lang=\"ruby\"><span class=\"k\">module</span> <span class=\"nn\">Gitlab</span></span>\n")
    end
  end

  describe '#diff_lines_for_serializer' do
    let(:diff_line_types) { conflict_file.diff_lines_for_serializer.map(&:type) }

    it 'assigns conflict types to the diff lines' do
      expect(diff_line_types[4]).to eq('conflict_marker_our')
      expect(diff_line_types[5..10]).to eq(['conflict_our'] * 6)
      expect(diff_line_types[11]).to eq('conflict_marker')
      expect(diff_line_types[12..17]).to eq(['conflict_their'] * 6)
      expect(diff_line_types[18]).to eq('conflict_marker_their')

      expect(diff_line_types[19..24]).to eq([nil] * 6)

      expect(diff_line_types[25]).to eq('conflict_marker_our')
      expect(diff_line_types[26..27]).to eq(['conflict_our'] * 2)
      expect(diff_line_types[28]).to eq('conflict_marker')
      expect(diff_line_types[29..30]).to eq(['conflict_their'] * 2)
      expect(diff_line_types[31]).to eq('conflict_marker_their')
    end

    # Swap the positions around due to conflicts/diffs display inconsistency
    # https://gitlab.com/gitlab-org/gitlab/-/issues/291989
    it 'swaps the new and old positions around' do
      lines = conflict_file.diff_lines_for_serializer
      expect(lines.map(&:old_pos)[26..27]).to eq([21, 22])
      expect(lines.map(&:new_pos)[29..30]).to eq([21, 22])
    end

    it 'does not add a match line to the end of the section' do
      expect(diff_line_types.last).to eq(nil)
    end

    context 'when there are unchanged trailing lines' do
      let(:conflict_file_name) { 'files/ruby/popen.rb' }

      it 'assign conflict types and adds match line to the end of the section' do
        expect(diff_line_types).to eq(
          [
            'match',
            nil, nil, nil,
            "conflict_marker_our",
            "conflict_our",
            "conflict_marker",
            "conflict_their",
            "conflict_their",
            "conflict_their",
            "conflict_marker_their",
            nil, nil, nil,
            "match"
          ])
      end
    end
  end

  describe '#sections' do
    it 'only inserts match lines when there is a gap between sections' do
      conflict_file.sections.each_with_index do |section, i|
        previous_line_number = 0
        current_line_number = section[:lines].map(&:old_line).compact.min

        if i > 0
          previous_line_number = conflict_file.sections[i - 1][:lines].map(&:old_line).compact.last
        end

        if current_line_number == previous_line_number + 1
          expect(section[:lines].first.type).not_to eq('match')
        else
          expect(section[:lines].first.type).to eq('match')
          expect(section[:lines].first.text).to match(/\A@@ -#{current_line_number},\d+ \+\d+,\d+ @@ module Gitlab\Z/)
        end
      end
    end

    it 'sets conflict to false for sections with only unchanged lines' do
      conflict_file.sections.reject { |section| section[:conflict] }.each do |section|
        without_match = section[:lines].reject { |line| line.type == 'match' }

        expect(without_match).to all(have_attributes(type: nil))
      end
    end

    it 'only includes a maximum of CONTEXT_LINES (plus an optional match line) in context sections' do
      conflict_file.sections.reject { |section| section[:conflict] }.each do |section|
        without_match = section[:lines].reject { |line| line.type == 'match' }

        expect(without_match.length).to be <= Gitlab::Conflict::File::CONTEXT_LINES * 2
      end
    end

    it 'sets conflict to true for sections with only changed lines' do
      conflict_file.sections.select { |section| section[:conflict] }.each do |section|
        section[:lines].each do |line|
          expect(line.type).to be_in(%w[new old])
        end
      end
    end

    it 'adds unique IDs to conflict sections, and not to other sections' do
      section_ids = []

      conflict_file.sections.each do |section|
        if section[:conflict]
          expect(section).to have_key(:id)
          section_ids << section[:id]
        else
          expect(section).not_to have_key(:id)
        end
      end

      expect(section_ids.uniq).to eq(section_ids)
    end

    context 'with an example file' do
      let(:raw_conflict_content) do
        <<~FILE
            # Ensure there is no match line header here
            def username_regexp
              default_regexp
            end

          <<<<<<< files/ruby/regex.rb
          def project_name_regexp
            /\A[a-zA-Z0-9][a-zA-Z0-9_\-\. ]*\z/
          end

          def name_regexp
            /\A[a-zA-Z0-9_\-\. ]*\z/
          =======
          def project_name_regex
            %r{\A[a-zA-Z0-9][a-zA-Z0-9_\-\. ]*\z}
          end

          def name_regex
            %r{\A[a-zA-Z0-9_\-\. ]*\z}
          >>>>>>> files/ruby/regex.rb
          end

          # Some extra lines
          # To force a match line
          # To be created

          def path_regexp
            default_regexp
          end

          <<<<<<< files/ruby/regex.rb
          def archive_formats_regexp
            /(zip|tar|7z|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)/
          =======
          def archive_formats_regex
            %r{(zip|tar|7z|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)}
          >>>>>>> files/ruby/regex.rb
          end

          def git_reference_regexp
            # Valid git ref regexp, see:
            # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
            %r{
              (?!
                 (?# doesn't begins with)
                 \/|                    (?# rule #6)
                 (?# doesn't contain)
                 .*(?:
                    [\/.]\.|            (?# rule #1,3)
                    \/\/|               (?# rule #6)
                    @\{|                (?# rule #8)
                    \\                  (?# rule #9)
                 )
              )
              [^\000-\040\177~^:?*\[]+  (?# rule #4-5)
              (?# doesn't end with)
              (?<!\.lock)               (?# rule #1)
              (?<![\/.])                (?# rule #6-7)
            }x
          end

          protected

          <<<<<<< files/ruby/regex.rb
          def default_regexp
            /\A[.?]?[a-zA-Z0-9][a-zA-Z0-9_\-\.]*(?<!\.git)\z/
          =======
          def default_regex
            %r{\A[.?]?[a-zA-Z0-9][a-zA-Z0-9_\-\.]*(?<!\.git)\z}
          >>>>>>> files/ruby/regex.rb
          end
        FILE
      end

      let(:conflict) { { ancestor: { path: '' }, theirs: { path: conflict_file_name }, ours: { path: conflict_file_name } } }
      let(:raw_conflict_file) { Gitlab::Git::Conflict::File.new(repository, our_commit, conflict, raw_conflict_content) }
      let(:sections) { conflict_file.sections }

      it 'sets the correct match line headers' do
        expect(sections[0][:lines].first).to have_attributes(type: 'match', text: '@@ -3,14 +3,14 @@')
        expect(sections[3][:lines].first).to have_attributes(type: 'match', text: '@@ -19,26 +19,26 @@ def path_regexp')
        expect(sections[6][:lines].first).to have_attributes(type: 'match', text: '@@ -47,52 +47,52 @@ end')
      end

      it 'does not add match lines where they are not needed' do
        expect(sections[1][:lines].first.type).not_to eq('match')
        expect(sections[2][:lines].first.type).not_to eq('match')
        expect(sections[4][:lines].first.type).not_to eq('match')
        expect(sections[5][:lines].first.type).not_to eq('match')
        expect(sections[7][:lines].first.type).not_to eq('match')
      end

      it 'creates context sections of the correct length' do
        expect(sections[0][:lines].count { |line| line.type.nil? }).to eq(3)
        expect(sections[2][:lines].count { |line| line.type.nil? }).to eq(3)
        expect(sections[3][:lines].count { |line| line.type.nil? }).to eq(3)
        expect(sections[5][:lines].count { |line| line.type.nil? }).to eq(3)
        expect(sections[6][:lines].count { |line| line.type.nil? }).to eq(3)
        expect(sections[8][:lines].count { |line| line.type.nil? }).to eq(1)
      end
    end
  end

  describe '#as_json' do
    it 'includes the blob path for the file' do
      expect(conflict_file.as_json[:blob_path])
        .to eq("/#{project.full_path}/-/blob/#{our_commit}/files/ruby/regex.rb")
    end

    it 'includes the blob icon for the file' do
      expect(conflict_file.as_json[:blob_icon]).to eq('doc-text')
    end

    context 'with the full_content option passed' do
      it 'includes the full content of the conflict' do
        expect(conflict_file.as_json(full_content: true)).to have_key(:content)
      end
    end
  end

  describe '#conflict_type' do
    using RSpec::Parameterized::TableSyntax

    let(:conflict) { { ancestor: { path: ancestor_path }, theirs: { path: their_path }, ours: { path: our_path } } }
    let(:raw_conflict_file) { Gitlab::Git::Conflict::File.new(repository, our_commit, conflict, '') }

    subject(:conflict_type) { conflict_file.conflict_type(when_renamed: renamed_file?) }

    where(:ancestor_path, :their_path, :our_path, :renamed_file?, :result) do
      '/ancestor/path' | '/their/path' | '/our/path' | false | :both_modified
      '/ancestor/path' | ''            | '/our/path' | false | :modified_source_removed_target
      '/ancestor/path' | '/their/path' | ''          | false | :modified_target_removed_source
      ''               | '/their/path' | '/our/path' | false | :both_added
      ''               | ''            | '/our/path' | false | :removed_target_renamed_source
      ''               | ''            | '/our/path' | true  | :renamed_same_file
      ''               | '/their/path' | ''          | false | :removed_source_renamed_target
    end

    with_them do
      it { expect(conflict_type).to eq(result) }
    end
  end
end
