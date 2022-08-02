# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRequest::Service do
  let(:ports) { [{ number: 80, protocol: 'http', name: 'name' }] }
  let(:service) do
    instance_double(
      ::Gitlab::Ci::Build::Image,
      name: 'image_name',
      entrypoint: ['foo'],
      ports: ports,
      pull_policy: ['if-not-present'],
      alias: 'alias',
      command: 'command',
      variables: [{ key: 'key', value: 'value' }]
    )
  end

  let(:entity) { described_class.new(service) }

  subject(:result) { entity.as_json }

  it 'exposes attributes' do
    expect(result).to eq(
      name: 'image_name',
      entrypoint: ['foo'],
      ports: ports,
      pull_policy: ['if-not-present'],
      alias: 'alias',
      command: 'command',
      variables: [{ key: 'key', value: 'value' }]
    )
  end

  context 'when the ports param is nil' do
    let(:ports) { nil }

    it 'does not return the ports' do
      expect(subject[:ports]).to be_nil
    end
  end

  context 'when the FF ci_docker_image_pull_policy is disabled' do
    before do
      stub_feature_flags(ci_docker_image_pull_policy: false)
    end

    it { is_expected.not_to have_key(:pull_policy) }
  end
end
