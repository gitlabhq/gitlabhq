# frozen_string_literal: true

RSpec::Matchers.define :have_pushed_frontend_feature_flags do |expected|
  def to_js(key, value)
    "\"#{key}\":#{value}"
  end

  def html(actual)
    actual.try(:html) || actual
  end

  match do |actual|
    expected.all? do |feature_flag_name, enabled|
      html(actual).include?(to_js(feature_flag_name, enabled))
    end
  end

  failure_message do |actual|
    missing = expected.select do |feature_flag_name, enabled|
      html(actual).exclude?(to_js(feature_flag_name, enabled))
    end

    formatted_missing_flags = missing.map { |feature_flag_name, enabled| to_js(feature_flag_name, enabled) }.join("\n")

    "The following feature flag(s) cannot be found in the frontend HTML source: #{formatted_missing_flags}"
  end
end
