# frozen_string_literal: true

RSpec::Matchers.define :have_pushed_licensed_features do |expected|
  def to_js(key, value)
    "\"#{key}\":#{value}"
  end

  def html(actual)
    actual.try(:html) || actual
  end

  match do |actual|
    expected.all? do |licensed_feature_name, enabled|
      html(actual).include?(to_js(licensed_feature_name, enabled))
    end
  end

  failure_message do |actual|
    missing = expected.select do |licensed_feature_name, enabled|
      html(actual).exclude?(to_js(licensed_feature_name, enabled))
    end

    missing_licensed_features = missing.map do |licensed_feature_name, enabled|
      to_js(licensed_feature_name, enabled)
    end.join("\n")

    "The following licensed feature(s) cannot be found in the frontend HTML source: #{missing_licensed_features}"
  end
end
