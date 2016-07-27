require 'spec_helper'

describe Gitlab::Conflict::File, lib: true do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:rugged) { repository.rugged }
  let(:their_commit) { rugged.branches['conflict-a'].target }
  let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: their_commit.oid, head_sha: our_commit.oid) }
  let(:our_commit) { rugged.branches['conflict-b'].target }
  let(:index) { rugged.merge_commits(our_commit, their_commit) }
  let(:conflict) { index.conflicts.last }
  let(:merge_file_result) { index.merge_file('files/ruby/regex.rb') }
  let(:conflict_file) { Gitlab::Conflict::File.new(merge_file_result, conflict, diff_refs: diff_refs, repository: repository) }

  describe '#highlighted_lines' do
    def html_to_text(html)
      CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(html)).delete("\n")
    end

    it 'returns lines with rich_text' do
      expect(conflict_file.highlighted_lines).to all(have_attributes(rich_text: a_kind_of(String)))
    end

    it 'returns lines with rich_text matching the text content of the line' do
      conflict_file.highlighted_lines.each do |line|
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
      expect(match_line.text).to eq('@@ -46,53 +46,53 @@')
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
  end
end
