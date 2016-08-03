require 'spec_helper'

describe Gitlab::Conflict::File, lib: true do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:rugged) { repository.rugged }
  let(:their_commit) { rugged.branches['conflict-a'].target }
  let(:our_commit) { rugged.branches['conflict-b'].target }
  let(:merge_request) { create(:merge_request, source_branch: 'conflict-b', target_branch: 'conflict-a', source_project: project) }
  let(:index) { rugged.merge_commits(our_commit, their_commit) }
  let(:conflict) { index.conflicts.last }
  let(:merge_file_result) { index.merge_file('files/ruby/regex.rb') }
  let(:conflict_file) { Gitlab::Conflict::File.new(merge_file_result, conflict, merge_request: merge_request) }

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
        expect(resolved_lines.chunk { |line| line.type || 'both' }.map(&:first)).
          to eq(['both', 'new', 'both', 'old', 'both', 'new', 'both'])
      end
    end

    it 'raises MissingResolution when passed a hash without resolutions for all sections' do
      empty_hash = section_keys.map { |key| [key, nil] }.to_h
      invalid_hash = section_keys.map { |key| [key, 'invalid'] }.to_h

      expect { conflict_file.resolve_lines({}) }.
        to raise_error(Gitlab::Conflict::File::MissingResolution)

      expect { conflict_file.resolve_lines(empty_hash) }.
        to raise_error(Gitlab::Conflict::File::MissingResolution)

      expect { conflict_file.resolve_lines(invalid_hash) }.
        to raise_error(Gitlab::Conflict::File::MissingResolution)
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
  end

  describe '#sections' do
    it 'returns match lines when there is a gap between sections' do
      section = conflict_file.sections[5]
      match_line = section[:lines][0]

      expect(section[:conflict]).to be_falsey
      expect(match_line.type).to eq('match')
      expect(match_line.text).to eq('@@ -46,53 +46,53 @@ module Gitlab')
    end

    it 'does not return match lines when there is no gap between sections' do
      conflict_file.sections.each_with_index do |section, i|
        unless i == 5
          expect(section[:lines][0].type).not_to eq(5)
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
          expect(line.type).to be_in(['new', 'old'])
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
  end

  describe '#as_json' do
    it 'includes the blob path for the file' do
      expect(conflict_file.as_json[:blob_path]).
        to eq("/#{project.namespace.to_param}/#{merge_request.project.to_param}/blob/#{our_commit.oid}/files/ruby/regex.rb")
    end

    it 'includes the blob icon for the file' do
      expect(conflict_file.as_json[:blob_icon]).to eq('file-text-o')
    end
  end
end
