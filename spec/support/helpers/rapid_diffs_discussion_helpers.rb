# frozen_string_literal: true

require_relative 'rapid_diffs_helpers'

module RapidDiffsDiscussionHelpers
  include RapidDiffsHelpers

  def line_cell(line_holder, diff_side = nil)
    return line_holder.find('[data-position="old"]', match: :first) if diff_side.nil?

    line_holder.find("[data-position='#{position_for(diff_side)}']", match: :first)
  end

  def line_link(line_holder, diff_side = nil)
    return line_holder.find('[data-line-number]', match: :first) if diff_side.nil?

    sided = "[data-position='#{position_for(diff_side)}'] [data-line-number]"
    return line_holder.find(sided, match: :first) if line_holder.has_css?(sided, wait: 1)

    line_holder.find('[data-line-number]', match: :first)
  end

  def line_by_number(file_path, side, number)
    diff_file(file_path)
      .find("[data-position='#{side}'] [data-line-number='#{number}']")
      .find(:xpath, './ancestor::tr[1]')
  end

  def find_line(line_code, file_path)
    _file_hash, old_line, new_line = line_code.split('_')
    diff_file(file_path).assert_selector('diff-file-mounted', visible: :all, wait: 10)
    selector = "[data-position='new'] [data-line-number='#{new_line}'], " \
      "[data-position='old'] [data-line-number='#{old_line}']"
    diff_file(file_path).find(selector, match: :first).find(:xpath, './ancestor::tr[1]')
  end

  def next_discussion_row(line_holder)
    line_holder.find(:xpath, './following-sibling::*[@data-discussion-row][1]')
  end

  def reveal_new_discussion_toggle(line_holder, diff_side = nil)
    scroll_to_center(line_holder)
    wait_for('new-discussion toggle to appear on the row') do
      line_link(line_holder, diff_side).hover
      has_testid?('new_discussion_toggle', context: line_holder, wait: 0.2).tap do |has_toggle|
        find_by_testid('super-topbar-search-button').hover unless has_toggle
      end
    end
    find_by_testid('new_discussion_toggle', context: line_holder)
  end

  def click_diff_line(line_holder, diff_side = nil)
    reveal_new_discussion_toggle(line_holder, diff_side).click
  end

  def comment_on_diff_line(line_holder, body, diff_side: nil, action: 'Add comment now')
    click_diff_line(line_holder, diff_side)
    next_discussion_row(line_holder).fill_in('note[note]', with: body)
    click_button(action)
  end

  def drag_comment_range(anchor_row, target_row, diff_side = nil)
    toggle = reveal_new_discussion_toggle(anchor_row, diff_side)
    scroll_to_center(target_row)
    target_cell = line_link(target_row, diff_side)

    page.execute_script(<<~JS, toggle.native, target_cell.native)
      const [toggle, targetCell] = arguments;
      const fire = (el, type, extra = {}) =>
        el.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, ...extra }));

      fire(toggle, 'dragstart');
      for (let i = 0; i < 3; i += 1) {
        const rect = targetCell.getBoundingClientRect();
        const clientX = rect.left + rect.width / 2;
        const clientY = rect.top + rect.height / 2;
        const target = document.elementFromPoint(clientX, clientY) || targetCell;
        fire(target, 'dragenter', { clientX, clientY });
        fire(target, 'dragover', { clientX, clientY });
      }
      fire(toggle, 'dragend');
    JS
  end

  def discussion_row_after_drag(anchor_row, target_row)
    if anchor_row.has_xpath?('./following-sibling::*[@data-discussion-row][1]', wait: 1)
      next_discussion_row(anchor_row)
    else
      next_discussion_row(target_row)
    end
  end

  def reply_to_thread(scope, body)
    within(scope) do
      find_by_testid('discussion-reply-tab').click
      find_by_testid('reply-field').set(body)
      find_by_testid('reply-comment-button').click

      expect(page).to have_testid('noteable-note-container', text: body)
    end
  end

  def open_note_actions(note)
    note.hover
    note.find('[data-testid="ellipsis_v-icon"]', match: :first).ancestor('button').click
  end

  def expand_all_collapsed_discussions
    loop do
      avatar = page.all('[data-testid="gutter-avatar"]', wait: 3).first
      break unless avatar

      # The wrapper survives the expand; the avatar button itself is replaced.
      gutter = avatar.ancestor('[data-gutter-toggle]')
      avatar.click

      expect(gutter).to have_testid('collapse-toggle')
    end
  end

  private

  def position_for(diff_side)
    diff_side == 'left' ? 'old' : 'new'
  end
end
