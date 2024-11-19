# frozen_string_literal: true

RSpec.shared_examples 'purl_types enum' do
  let(:purl_types) do
    {
      composer: 1,
      conan: 2,
      gem: 3,
      golang: 4,
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      'cbl-mariner': 12,
      wolfi: 13,
      cargo: 14,
      swift: 15,
      conda: 16
    }
  end

  it { is_expected.to define_enum_for(:purl_type).with_values(purl_types) }
end
