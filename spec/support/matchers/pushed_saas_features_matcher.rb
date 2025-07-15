# frozen_string_literal: true

RSpec::Matchers.define :have_pushed_saas_features do |expected|
  def to_js(key, value)
    "\"#{key}\":#{value}"
  end

  def html(actual)
    actual.try(:html) || actual
  end

  match do |actual|
    expected.all? do |saas_feature_name, enabled|
      html(actual).include?(to_js(saas_feature_name, enabled))
    end
  end

  failure_message do |actual|
    missing = expected.select do |saas_feature_name, enabled|
      html(actual).exclude?(to_js(saas_feature_name, enabled))
    end

    missing_saas_features = missing.map do |saas_feature_name, enabled|
      to_js(saas_feature_name, enabled)
    end.join("\n")

    "The following SaaS feature(s) cannot be found in the frontend HTML source: #{missing_saas_features}"
  end
end
