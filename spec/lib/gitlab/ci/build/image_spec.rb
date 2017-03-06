require 'spec_helper'

describe Gitlab::Ci::Build::Image do
  let(:job) { create(:ci_build, :no_options) }

  describe '#from_image' do
    subject { described_class.from_image(job) }

    context 'when image is defined in job' do
      let(:image_name) { 'ruby:2.1' }
      let(:job) { create(:ci_build, options: { image: image_name } ) }

      it { is_expected.to be_kind_of(described_class) }
      it { expect(subject.name).to eq(image_name) }

      context 'when image name is empty' do
        let(:image_name) { '' }

        it { is_expected.to eq(nil) }
      end
    end

    context 'when image is not defined in job' do
      it { is_expected.to eq(nil) }
    end
  end

  describe '#from_services' do
    subject { described_class.from_services(job) }

    context 'when services are defined in job' do
      let(:service_image_name) { 'postgres' }
      let(:job) { create(:ci_build, options: { services: [service_image_name] }) }

      it { is_expected.to be_kind_of(Array) }
      it { is_expected.not_to be_empty }
      it { expect(subject[0].name).to eq(service_image_name) }

      context 'when service image name is empty' do
        let(:service_image_name) { '' }

        it { is_expected.to be_kind_of(Array) }
        it { is_expected.to be_empty }
      end
    end

    context 'when services are not defined in job' do
      it { is_expected.to be_kind_of(Array) }
      it { is_expected.to be_empty }
    end
  end
end
