# frozen_string_literal: true

RSpec.shared_examples 'parsable alert payload field with fallback' do |fallback, *paths|
  context 'without payload' do
    it { is_expected.to eq(fallback) }
  end

  paths.each do |path|
    context "with #{path}" do
      let(:value) { 'some value' }

      before do
        section, name = path.split('/')
        raw_payload[section] = name ? { name => value } : value
      end

      it { is_expected.to eq(value) }
    end
  end
end

RSpec.shared_examples 'parsable alert payload field' do |*paths|
  it_behaves_like 'parsable alert payload field with fallback', nil, *paths
end

RSpec.shared_examples 'subclass has expected api' do
  it 'defines all public methods in the base class' do
    default_methods = Gitlab::AlertManagement::Payload::Base.public_instance_methods
    subclass_methods = described_class.public_instance_methods
    missing_methods = subclass_methods - default_methods

    expect(missing_methods).to be_empty
  end
end
