# frozen_string_literal: true

RSpec.shared_examples 'when regex matching everything is specified' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    { 'name_regex_delete' => '.*' }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations

  context 'with deprecated name_regex param' do
    let(:params) do
      { 'name_regex' => '.*' }
    end

    it_behaves_like 'removing the expected tags',
      service_response_extra: service_response_extra,
      supports_caching: supports_caching,
      delete_expectations: delete_expectations
  end
end

RSpec.shared_examples 'when regex matching everything is specified and latest is not kept' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|

  let(:params) do
    { 'name_regex_delete' => '.*', 'keep_latest' => false }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations
end

RSpec.shared_examples 'when delete regex matching specific tags is used' do
  |service_response_extra: {}, supports_caching: false|
  let(:params) do
    { 'name_regex_delete' => 'C|D' }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: [%w[C D]]
end

RSpec.shared_examples 'when delete regex matching specific tags is used with overriding allow regex' do
  |service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex_delete' => 'C|D',
      'name_regex_keep' => 'C'
    }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: [%w[D]]

  context 'with name_regex_delete overriding deprecated name_regex' do
    let(:params) do
      {
        'name_regex' => 'C|D',
        'name_regex_delete' => 'D'
      }
    end

    it_behaves_like 'removing the expected tags',
      service_response_extra: service_response_extra,
      supports_caching: supports_caching,
      delete_expectations: [%w[D]]
  end
end

RSpec.shared_examples 'with allow regex value' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'name_regex_keep' => 'B.*'
    }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations
end

RSpec.shared_examples 'when keeping only N tags' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex' => 'A|B.*|C',
      'keep_n' => 1
    }
  end

  it 'sorts tags by date' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    expect(service).to receive(:order_by_date_desc).at_least(:once).and_call_original

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end

RSpec.shared_examples 'when not keeping N tags' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    { 'name_regex' => 'A|B.*|C' }
  end

  it 'does not sort tags by date' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    expect(service).not_to receive(:order_by_date_desc)

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end

RSpec.shared_examples 'when removing keeping only 3' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    { 'name_regex_delete' => '.*',
      'keep_n' => 3 }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations
end

RSpec.shared_examples 'when removing older than 1 day' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'older_than' => '1 day'
    }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations
end

RSpec.shared_examples 'when combining all parameters' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:params) do
    {
      'name_regex_delete' => '.*',
      'keep_n' => 1,
      'older_than' => '1 day'
    }
  end

  it_behaves_like 'removing the expected tags',
    service_response_extra: service_response_extra,
    supports_caching: supports_caching,
    delete_expectations: delete_expectations
end

RSpec.shared_examples 'when running a container_expiration_policy' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  let(:user) { nil }

  context 'with valid container_expiration_policy param' do
    let(:params) do
      {
        'name_regex_delete' => '.*',
        'keep_n' => 1,
        'older_than' => '1 day',
        'container_expiration_policy' => true
      }
    end

    it 'removes the expected tags' do
      delete_expectations.each { |expectation| expect_delete(expectation, container_expiration_policy: true) }
      expect_no_caching unless supports_caching

      is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
    end
  end
end

RSpec.shared_examples 'not removing anything' do |service_response_extra: {}, supports_caching: false|
  it 'does not remove anything' do
    expect(Projects::ContainerRepository::DeleteTagsService).not_to receive(:new)
    expect_no_caching unless supports_caching

    is_expected.to eq(expected_service_response(deleted: []).merge(service_response_extra))
  end
end

RSpec.shared_examples 'removing the expected tags' do
  |delete_expectations:, service_response_extra: {}, supports_caching: false|
  it 'removes the expected tags' do
    delete_expectations.each { |expectation| expect_delete(expectation) }
    expect_no_caching unless supports_caching

    is_expected.to eq(expected_service_response(deleted: delete_expectations.flatten).merge(service_response_extra))
  end
end
