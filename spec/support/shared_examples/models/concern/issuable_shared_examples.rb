shared_examples_for 'matches_cross_reference_regex? fails fast' do
  it 'fails fast for long strings' do
    # took well under 1 second in CI https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3267#note_172823
    expect do
      Timeout.timeout(6.seconds) { mentionable.matches_cross_reference_regex? }
    end.not_to raise_error
  end
end
