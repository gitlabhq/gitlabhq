module MergeRequestDiffHelpers
  def click_diff_line(line_holder, diff_side = nil)
    line = get_line_components(line_holder, diff_side)
    line[:content].hover
    line[:num].find('.add-diff-note', visible: false).send_keys(:return)
  end

  def get_line_components(line_holder, diff_side = nil)
    if diff_side.nil?
      get_inline_line_components(line_holder)
    else
      get_parallel_line_components(line_holder, diff_side)
    end
  end

  def get_inline_line_components(line_holder)
    { content: line_holder.find('.line_content', match: :first), num: line_holder.find('.diff-line-num', match: :first) }
  end

  def get_parallel_line_components(line_holder, diff_side = nil)
    side_index = diff_side == 'left' ? 0 : 1
    # Wait for `.line_content`
    line_holder.find('.line_content', match: :first)
    # Wait for `.diff-line-num`
    line_holder.find('.diff-line-num', match: :first)
    { content: line_holder.all('.line_content')[side_index], num: line_holder.all('.diff-line-num')[side_index] }
  end
end
