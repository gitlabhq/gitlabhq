# frozen_string_literal: true

module ReloadHelpers
  def reload_models(*models)
    models.map(&:reload)
  end

  def subject_and_reload(*models)
    subject
    reload_models(*models)
  end
end
