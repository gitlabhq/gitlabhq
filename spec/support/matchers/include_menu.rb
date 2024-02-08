# frozen_string_literal: true

RSpec::Matchers.define :include_menu do |expected|
  match do |actual|
    menus = actual.instance_variable_get(:@menus)
    expect(menus).to include(expected)
  end
end
