require 'spec_helper'

describe Gitlab::Conflict::File do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:rugged) { repository.rugged }
  let(:their_commit) { rugged.branches['conflict-start'].target }
  let(:our_commit) { rugged.branches['conflict-resolvable'].target }
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project) }
  let(:index) { rugged.merge_commits(our_commit, their_commit) }
  let(:rugged_conflict) { index.conflicts.last }
  let(:raw_conflict_content) { index.merge_file('files/ruby/regex.rb')[:data] }
  let(:raw_conflict_file) { Gitlab::Git::Conflict::File.new(repository, our_commit.oid, rugged_conflict, raw_conflict_content) }
  let(:conflict_file) { described_class.new(raw_conflict_file, merge_request: merge_request) }

  describe '#resolve_lines' do
    let(:section_keys) { conflict_file.sections.map { |section| section[:id] }.compact }

    context 'when resolving everything to the same side' do
      let(:resolution_hash) { section_keys.map { |key| [key, 'head'] }.to_h }
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
          .to eq(%w(both new both old both new both))
      end
    end

    it 'raises ResolutionError when passed a hash without resolutions for all sections' do
      empty_hash = section_keys.map { |key| [key, nil] }.to_h
      invalid_hash = section_keys.map { |key| [key, 'invalid'] }.to_h

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

    it 'modifies the existing lines' do
      expect { conflict_file.highlight_lines! }.to change { conflict_file.lines.map(&:instance_variables) }
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
          expect(line.type).to be_in(%w(new old))
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
        <<FILE
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
        expect(sections[0][:lines].reject(&:type).length).to eq(3)
        expect(sections[2][:lines].reject(&:type).length).to eq(3)
        expect(sections[3][:lines].reject(&:type).length).to eq(3)
        expect(sections[5][:lines].reject(&:type).length).to eq(3)
        expect(sections[6][:lines].reject(&:type).length).to eq(3)
        expect(sections[8][:lines].reject(&:type).length).to eq(1)
      end
    end
  end

  describe '#as_json' do
    it 'includes the blob path for the file' do
      expect(conflict_file.as_json[:blob_path])
        .to eq("/#{project.full_path}/blob/#{our_commit.oid}/files/ruby/regex.rb")
    end

    it 'includes the blob icon for the file' do
      expect(conflict_file.as_json[:blob_icon]).to eq('file-text-o')
    end

    context 'with the full_content option passed' do
      it 'includes the full content of the conflict' do
        expect(conflict_file.as_json(full_content: true)).to have_key(:content)
      end

      it 'includes the detected language of the conflict file' do
        expect(conflict_file.as_json(full_content: true)[:blob_ace_mode])
          .to eq('ruby')
      end
    end
  end
end
