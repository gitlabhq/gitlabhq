RSpec::Matchers.define :have_incremented do |counter|
  match do |adapter|
    matcher = RSpec::Mocks::Matchers::HaveReceived.new(:increment)

    matcher.matches?(adapter.send(counter))
  end
end
