# frozen_string_literal: true

RSpec::Matchers.define :execute_check do |expected|
  match do |actual|
    expect(actual).to eq(SystemCheck)
    expect(actual).to receive(:run) do |*args|
      expect(args[1]).to include(expected)
    end
  end

  match_when_negated do |actual|
    expect(actual).to eq(SystemCheck)
    expect(actual).to receive(:run) do |*args|
      expect(args[1]).not_to include(expected)
    end
  end

  failure_message do |actual|
    'This matcher must be used with SystemCheck' unless actual == SystemCheck
  end

  failure_message_when_negated do |actual|
    'This matcher must be used with SystemCheck' unless actual == SystemCheck
  end
end
