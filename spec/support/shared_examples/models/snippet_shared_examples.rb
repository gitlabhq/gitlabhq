# frozen_string_literal: true

RSpec.shared_examples 'size checker for snippet' do |action|
  it 'sets up size checker', :aggregate_failures do
    expect(checker.current_size).to eq(current_size.megabytes)
    expect(checker.limit).to eq(Gitlab::CurrentSettings.snippet_size_limit)
    expect(checker.total_repository_size_excess).to eq(total_repository_size_excess)
    expect(checker.additional_purchased_storage).to eq(additional_purchased_storage)
    expect(checker.enabled?).to eq(true)
  end
end
