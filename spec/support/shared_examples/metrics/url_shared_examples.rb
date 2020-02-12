# frozen_string_literal: true

RSpec.shared_examples 'regex which matches url when expected' do
  it { is_expected.to be_a Regexp }

  it 'matches a metrics dashboard link with named params' do
    expect(subject).to match url

    subject.match(url) do |m|
      expect(m.named_captures).to eq expected_params
    end
  end

  it 'does not match other gitlab urls that contain the term metrics' do
    url = Gitlab::Routing.url_helpers.active_common_namespace_project_prometheus_metrics_url('foo', 'bar', :json)

    expect(subject).not_to match url
  end

  it 'does not match other gitlab urls' do
    url = Gitlab.config.gitlab.url

    expect(subject).not_to match url
  end

  it 'does not match non-gitlab urls' do
    url = 'https://www.super_awesome_site.com/'

    expect(subject).not_to match url
  end
end
