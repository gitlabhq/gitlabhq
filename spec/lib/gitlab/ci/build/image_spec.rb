# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Image do
  let(:job) { create(:ci_build, options: job_options) }

  describe '#from_image' do
    subject(:from_image) { described_class.from_image(job) }

    context 'when image is defined in job' do
      let(:image_name) { 'image:1.0' }
      let(:job_options) { { image: image } }

      context 'when image is defined as string' do
        let(:image) { image_name }

        it 'fabricates an object of the proper class' do
          is_expected.to be_kind_of(described_class)
        end

        it 'populates fabricated object with the proper name attribute' do
          expect(from_image.name).to eq(image_name)
        end

        it 'does not populate the ports' do
          expect(from_image.ports).to be_empty
        end
      end

      context 'when image is defined as hash' do
        let(:entrypoint) { '/bin/sh' }
        let(:pull_policy) { %w[always if-not-present] }
        let(:executor_opts) { { docker: { platform: 'arm64', user: 'dave' } } }

        let(:job_options) do
          {
            image: {
              name: image_name,
              entrypoint: entrypoint,
              ports: [80],
              executor_opts: executor_opts,
              pull_policy: pull_policy
            }
          }
        end

        it 'fabricates an object of the proper class' do
          is_expected.to be_kind_of(described_class)
        end

        it 'populates fabricated object with the proper attributes' do
          expect(from_image.name).to eq(image_name)
          expect(from_image.entrypoint).to eq(entrypoint)
          expect(from_image.executor_opts).to eq(executor_opts)
          expect(from_image.pull_policy).to eq(pull_policy)
        end

        it 'populates the ports' do
          port = from_image.ports.first
          expect(port.number).to eq 80
          expect(port.protocol).to eq 'http'
          expect(port.name).to eq 'default_port'
        end

        context 'when kubernetes executor options is defined as hash' do
          let(:executor_opts) { { kubernetes: { user: '1001:1001' } } }

          it 'fabricates an object of the proper class' do
            is_expected.to be_kind_of(described_class)
          end

          it 'populates fabricated object with the proper attributes' do
            expect(subject.name).to eq(image_name)
            expect(subject.entrypoint).to eq(entrypoint)
            expect(subject.executor_opts).to eq(executor_opts)
            expect(subject.pull_policy).to eq(pull_policy)
          end

          it 'populates the ports' do
            port = subject.ports.first
            expect(port.number).to eq 80
            expect(port.protocol).to eq 'http'
            expect(port.name).to eq 'default_port'
          end
        end
      end

      context 'when image is empty' do
        let(:image) { '' }

        it 'does not fabricate an object' do
          is_expected.to be_nil
        end
      end
    end

    context 'when image is not defined in job' do
      let(:job_options) { {} }

      it 'does not fabricate an object' do
        is_expected.to be_nil
      end
    end
  end

  describe '#from_services' do
    subject(:from_services) { described_class.from_services(job) }

    context 'when services are defined in job' do
      let(:service_image_name) { 'postgres' }
      let(:job_options) { { services: [service] } }

      context 'when service is defined as string' do
        let(:service) { service_image_name }

        it 'fabricates an non-empty array of objects' do
          is_expected.to be_kind_of(Array)
          is_expected.not_to be_empty
        end

        it 'populates fabricated objects with the proper name attributes' do
          expect(from_services.first).to be_kind_of(described_class)
          expect(from_services.first.name).to eq(service_image_name)
        end

        it 'does not populate the ports' do
          expect(from_services.first.ports).to be_empty
        end

        context 'when service image name is empty' do
          let(:service_image_name) { '' }

          it 'fabricates an empty array' do
            is_expected.to be_kind_of(Array)
            is_expected.to be_empty
          end
        end
      end

      context 'when service is defined as hash' do
        let(:service_entrypoint) { '/bin/sh' }
        let(:service_alias) { 'db' }
        let(:service_command) { 'sleep 30' }
        let(:executor_opts) { { docker: { platform: 'amd64', user: 'dave' } } }
        let(:pull_policy) { %w[always if-not-present] }
        let(:service) do
          {
            name: service_image_name, entrypoint: service_entrypoint,
            alias: service_alias, command: service_command, ports: [80],
            executor_opts: executor_opts, pull_policy: pull_policy
          }
        end

        it 'fabricates an non-empty array of objects' do
          is_expected.to be_kind_of(Array)
          is_expected.not_to be_empty
          expect(from_services.first).to be_kind_of(described_class)
        end

        it 'populates fabricated objects with the proper attributes' do
          expect(from_services.first.name).to eq(service_image_name)
          expect(from_services.first.entrypoint).to eq(service_entrypoint)
          expect(from_services.first.alias).to eq(service_alias)
          expect(from_services.first.command).to eq(service_command)
          expect(from_services.first.executor_opts).to eq(executor_opts)
          expect(from_services.first.pull_policy).to eq(pull_policy)

          port = from_services.first.ports.first
          expect(port.number).to eq 80
          expect(port.protocol).to eq 'http'
          expect(port.name).to eq 'default_port'
        end

        context 'when kubernetes executor options is defined as hash' do
          let(:executor_opts) { { kubernetes: { user: '1001:1001' } } }

          it 'fabricates an non-empty array of objects' do
            is_expected.to be_kind_of(Array)
            is_expected.not_to be_empty
            expect(from_services.first).to be_kind_of(described_class)
          end

          it 'populates fabricated objects with the proper attributes' do
            expect(from_services.first.name).to eq(service_image_name)
            expect(from_services.first.entrypoint).to eq(service_entrypoint)
            expect(from_services.first.alias).to eq(service_alias)
            expect(from_services.first.command).to eq(service_command)
            expect(from_services.first.executor_opts).to eq(executor_opts)
            expect(from_services.first.pull_policy).to eq(pull_policy)

            port = from_services.first.ports.first
            expect(port.number).to eq 80
            expect(port.protocol).to eq 'http'
            expect(port.name).to eq 'default_port'
          end
        end
      end
    end

    context 'when services are not defined in job' do
      let(:job_options) { {} }

      it 'fabricates an empty array' do
        is_expected.to be_kind_of(Array)
        is_expected.to be_empty
      end
    end
  end
end
