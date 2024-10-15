# frozen_string_literal: true

RSpec::Matchers.define :have_pushed_frontend_ability do |expected|
  def to_js(key, value)
    "\"#{key}\":#{value}"
  end

  def html(actual)
    actual.try(:html) || actual
  end

  match do |actual|
    expected.all? do |ability_name, allowed|
      html(actual).include?(to_js(ability_name, allowed))
    end
  end

  failure_message do |actual|
    missing = expected.select do |ability_name, allowed|
      html(actual).exclude?(to_js(ability_name, allowed))
    end

    formatted_missing_abilities = missing.map { |ability_name, allowed| to_js(ability_name, allowed) }.join("\n")

    "The following abilities cannot be found in the frontend HTML source: #{formatted_missing_abilities}"
  end
end
