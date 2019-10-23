# frozen_string_literal: true

def forbid_controller_ability!(ability)
  allow(controller).to receive(:can?).and_call_original
  allow(controller).to receive(:can?).with(anything, ability, any_args).and_return(false)
end
