# frozen_string_literal: true

RSpec.shared_examples 'milestone handling version conflicts' do
  it 'warns about version conflict when milestone has been updated in the background', :js do
    wait_for_all_requests

    # Update the milestone in the background in order to trigger a version conflict
    milestone.update!(title: "New title")

    fill_in _('Title'), with: 'Title for version conflict'
    fill_in _('Description'), with: 'Description for version conflict'

    click_button _('Save changes')

    expect(page).to have_content(
      format(
        _("Someone edited this %{model_name} at the same time you did. Please check out the %{link_to_model} and make sure your changes will not unintentionally remove theirs."),
        model_name: _('milestone'),
        link_to_model: _('milestone')
      )
    )
  end
end
