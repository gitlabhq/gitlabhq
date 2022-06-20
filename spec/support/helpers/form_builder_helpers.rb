# frozen_string_literal: true

module FormBuilderHelpers
  def fake_action_view_base
    lookup_context = ActionView::LookupContext.new(ActionController::Base.view_paths)

    ActionView::Base.new(lookup_context, {}, ApplicationController.new)
  end

  def fake_form_for(&block)
    fake_action_view_base.form_for :user, url: '/user', &block
  end
end
