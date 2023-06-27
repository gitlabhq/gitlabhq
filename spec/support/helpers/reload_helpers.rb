# frozen_string_literal: true

module ReloadHelpers
  def reload_models(*models)
    models.compact.map(&:reload)
  end
end
