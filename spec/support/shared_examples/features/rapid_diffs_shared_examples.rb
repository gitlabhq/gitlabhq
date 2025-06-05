# frozen_string_literal: true

RSpec.shared_examples 'Rapid Diffs application' do
  include RapidDiffsHelpers

  describe 'diffs list' do
    it 'shows all diffs' do
      diffs.diff_files.each do |diff_file|
        file_path = if diff_file.submodule?
                      "#{diff_file.file_path} @ #{Commit.truncate_sha(diff_file.blob.id)}"
                    else
                      diff_file.file_path
                    end

        file = page.find('[data-testid="rd-diff-file"] h2', text: file_path, exact_text: true)
                   .find(:xpath, './ancestor::*[@data-testid="rd-diff-file"][1]')
        expect(file).not_to be_nil
        # ensure file is completely loaded
        file.find('diff-file-mounted', visible: :all)
        file_text = file.native[:textContent]
        diff_file.diff_lines.each do |line|
          expect(file_text).to include(line.text_content)
        end
      end
    end

    describe 'line expansion' do
      let(:file) { button.find(:xpath, './ancestor::*[@data-testid="rd-diff-file"][1]') }
      let(:row) { button.find(:xpath, './ancestor::tr[1]') }
      let(:next_row) { row.find(:xpath, './following-sibling::*[1]') }
      let(:prev_row) { row.find(:xpath, './preceding-sibling::*[1]') }
      let(:next_line_number) { next_row.find('[data-position="new"] [data-line-number]')['data-line-number'].to_i }
      let(:prev_line_number) { prev_row.find('[data-position="new"] [data-line-number]')['data-line-number'].to_i }

      context 'with expand up button' do
        let(:button) { expand_button('up') }

        it 'expands lines up' do
          skip 'button not found' if button.nil?

          next_ln = next_line_number - 1
          button.click
          expect(file).to have_css("[data-position=\"new\"] [data-line-number=\"#{next_ln}\"]")
        end
      end

      context 'with expand down button' do
        let(:button) { expand_button('down') }

        it 'expands lines down' do
          skip 'button not found' if button.nil?

          prev_ln = prev_line_number + 1
          button.click
          expect(file).to have_css("[data-position=\"new\"] [data-line-number=\"#{prev_ln}\"]")
        end
      end

      context 'with expand both button' do
        let(:button) { expand_button('both') }

        it 'expands all lines' do
          skip 'button not found' if button.nil?

          next_ln = next_line_number - 1
          prev_ln = prev_line_number + 1
          button.click
          expect(file).to have_css("[data-position=\"new\"] [data-line-number=\"#{next_ln}\"]")
          expect(file).to have_css("[data-position=\"new\"] [data-line-number=\"#{prev_ln}\"]")
        end
      end

      def expand_button(direction)
        page.first("button[data-expand-direction=\"#{direction}\"]", wait: 0.5)
      rescue StandardError
        nil
      end
    end
  end

  describe 'view settings' do
    it 'switches to parallel view' do
      expect(page).to have_css('[data-testid="hunk-lines-inline"]')
      expect(page).not_to have_css('[data-testid="hunk-lines-parallel"]')

      open_diff_view_preferences
      expect(inline_view_option['aria-selected']).to eq('true')
      expect(parallel_view_option['aria-selected']).not_to eq('true')

      select_parallel_view
      open_diff_view_preferences

      expect(inline_view_option['aria-selected']).not_to eq('true')
      expect(parallel_view_option['aria-selected']).to eq('true')
      expect(page).not_to have_css('[data-testid="hunk-lines-inline"]')
      expect(page).to have_css('[data-testid="hunk-lines-parallel"]')
    end
  end

  describe 'file browser' do
    let(:tree) { page.find('[data-testid="tree-list-scroll"]') }
    let(:tree_item_selector) { 'button[data-file-row]' }

    it 'has matching diff file order' do
      browser_item_titles = page.find_all(tree_item_selector).map { |element| tree_item_title(element) }
      diff_titles = page.find_all('diff-file header h2').map do |element|
        element.text.delete("\n").sub(/ @ .*/, '').strip
      end
      expect(browser_item_titles.each_with_index.all? do |browser_item_title, index|
        diff_titles[index].end_with?(browser_item_title)
      end).to be(true)
    end

    it 'navigates to the last file' do
      page.execute_script('arguments[0].scrollTop = arguments[0].scrollHeight', tree)
      last_item = page.all(tree_item_selector).last
      file_name = tree_item_title(last_item)
      last_item.click
      expect(page).to have_css("[data-testid=\"rd-diff-file\"]", text: file_name, visible: :visible)
    end

    def tree_item_title(item)
      item.find('[title]')['title']
    end
  end

  it 'passes axe automated accessibility testing' do
    # remove 'color-contrast' when code highlight themes conform to a contrast of 4.5:1
    expect(page).to be_axe_clean.within('[data-rapid-diffs]').skipping :'color-contrast'
  end
end
