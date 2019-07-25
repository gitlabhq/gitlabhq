# frozen_string_literal: true

RSpec::Matchers.define :increment do |counter|
  match do |adapter|
    expect(adapter.send(counter))
      .to receive(:increment)
      .exactly(@exactly || :once)
  end

  chain :twice do
    @exactly = :twice
  end
end
