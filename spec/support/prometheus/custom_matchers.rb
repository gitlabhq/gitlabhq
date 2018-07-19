RSpec::Matchers.define :increment do |counter|
  match do |metric|
    expect(metric.send(counter)).to receive(:increment)
  end
end
