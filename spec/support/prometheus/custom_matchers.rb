RSpec::Matchers.define :increment do |counter|
  match do |adapter|
    expect(adapter.send(counter)).to receive(:increment)
  end
end
