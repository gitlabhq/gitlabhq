# frozen_string_literal: true

RSpec.shared_examples 'size checker for snippet' do |action|
  it 'sets up size checker', :aggregate_failures do
    expect(checker.current_size).to eq(current_size.megabytes)
    expect(checker.limit).to eq(Gitlab::CurrentSettings.snippet_size_limit)
    expect(checker.enabled?).to eq(true)
    expect(checker.instance_variable_get(:@namespace)).to eq(namespace)
  end
end
