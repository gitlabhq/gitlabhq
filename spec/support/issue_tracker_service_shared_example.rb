RSpec.shared_examples 'issue tracker service URL attribute' do |url_attr|
  it { is_expected.to allow_value('https://example.com').for(url_attr) }

  it { is_expected.not_to allow_value('example.com').for(url_attr) }
  it { is_expected.not_to allow_value('ftp://example.com').for(url_attr) }
  it { is_expected.not_to allow_value('herp-and-derp').for(url_attr) }
end
