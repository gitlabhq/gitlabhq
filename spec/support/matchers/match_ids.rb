RSpec::Matchers.define :match_ids do |*expected|
  match do |actual|
    actual_ids = map_ids(actual)
    expected_ids = map_ids(expected)

    expect(actual_ids).to match_array(expected_ids)
  end

  description do
    'matches elements by ids'
  end

  def map_ids(elements)
    elements = elements.flatten if elements.respond_to?(:flatten)

    if elements.respond_to?(:map)
      elements.map(&:id)
    elsif elements.respond_to?(:id)
      [elements.id]
    else
      raise ArgumentError, "could not map elements to ids: #{elements}"
    end
  end
end
