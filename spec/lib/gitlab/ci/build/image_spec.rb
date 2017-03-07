require 'spec_helper'

describe Gitlab::Ci::Build::Image do
  let(:job) { create(:ci_build, :no_options) }

  describe '#from_image' do
    subject { described_class.from_image(job) }

    context 'when image is defined in job' do
      let(:image_name) { 'ruby:2.1' }
      let(:job) { create(:ci_build, options: { image: image_name } ) }

      it 'fabricates an object of the proper class' do
        is_expected.to be_kind_of(described_class)
      end

      it 'populates fabricated object with the proper name attribute' do
        expect(subject.name).to eq(image_name)
      end

      context 'when image name is empty' do
        let(:image_name) { '' }

        it 'does not fabricate an object' do
          is_expected.to be_nil
        end
      end
    end

    context 'when image is not defined in job' do
      it 'does not fabricate an object' do
        is_expected.to be_nil
      end
    end
  end

  describe '#from_services' do
    subject { described_class.from_services(job) }

    context 'when services are defined in job' do
      let(:service_image_name) { 'postgres' }
      let(:job) { create(:ci_build, options: { services: [service_image_name] }) }

      it 'fabricates an non-empty array of objects' do
        is_expected.to be_kind_of(Array)
        is_expected.not_to be_empty
        expect(subject.first.name).to eq(service_image_name)
      end

      context 'when service image name is empty' do
        let(:service_image_name) { '' }

        it 'fabricates an empty array' do
          is_expected.to be_kind_of(Array)
          is_expected.to be_empty
        end
      end
    end

    context 'when services are not defined in job' do
      it 'fabricates an empty array' do
        is_expected.to be_kind_of(Array)
        is_expected.to be_empty
      end
    end
  end
end
