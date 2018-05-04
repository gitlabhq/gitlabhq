shared_examples 'malicious regexp' do
  let(:malicious_text)  { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!' }
  let(:malicious_regexp) { '(?i)^(([a-z])+.)+[A-Z]([a-z])+$' }

  it 'takes under a second' do
    expect { Timeout.timeout(1) { subject } }.not_to raise_error
  end
end
