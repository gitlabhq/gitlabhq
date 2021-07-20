# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRequest::Image do
  let(:ports) { [{ number: 80, protocol: 'http', name: 'name' }]}
  let(:image) { double(name: 'image_name', entrypoint: ['foo'], ports: ports)}
  let(:entity) { described_class.new(image) }

  subject { entity.as_json }

  it 'returns the image name' do
    expect(subject[:name]).to eq 'image_name'
  end

  it 'returns the entrypoint' do
    expect(subject[:entrypoint]).to eq ['foo']
  end

  it 'returns the ports' do
    expect(subject[:ports]).to eq ports
  end

  context 'when the ports param is nil' do
    let(:ports) { nil }

    it 'does not return the ports' do
      expect(subject[:ports]).to be_nil
    end
  end
end
