module TargetBranchHelpers
  def select_branch(name)
    first('button.js-target-branch').click
    wait_for_requests
    all('a[data-group="Branches"]').find do |el|
      el.text == name
    end.click
  end

  def create_new_branch(name)
    first('button.js-target-branch').click
    click_link 'Create new branch'
    fill_in 'new_branch_name', with: name
    click_button 'Create'
  end
end
