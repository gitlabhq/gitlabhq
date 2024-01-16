# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Image do
  let(:job) { create(:ci_build, :no_options) }

  describe '#from_image' do
    subject { described_class.from_image(job) }

    context 'when image is defined in job' do
      let(:image_name) { 'image:1.0' }
      let(:job) { create(:ci_build, options: { image: image_name }) }

      context 'when image is defined as string' do
        it 'fabricates an object of the proper class' do
          is_expected.to be_kind_of(described_class)
        end

        it 'populates fabricated object with the proper name attribute' do
          expect(subject.name).to eq(image_name)
        end

        it 'does not populate the ports' do
          expect(subject.ports).to be_empty
        end
      end

      context 'when image is defined as hash' do
        let(:entrypoint) { '/bin/sh' }
        let(:pull_policy) { %w[always if-not-present] }
        let(:executor_opts) { { docker: { platform: 'arm64', user: 'dave' } } }

        let(:job) do
          create(:ci_build, options: { image: { name: image_name,
                                                entrypoint: entrypoint,
                                                ports: [80],
                                                executor_opts: executor_opts,
                                                pull_policy: pull_policy } })
        end

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

      context 'when service is defined as string' do
        it 'fabricates an non-empty array of objects' do
          is_expected.to be_kind_of(Array)
          is_expected.not_to be_empty
        end

        it 'populates fabricated objects with the proper name attributes' do
          expect(subject.first).to be_kind_of(described_class)
          expect(subject.first.name).to eq(service_image_name)
        end

        it 'does not populate the ports' do
          expect(subject.first.ports).to be_empty
        end
      end

      context 'when service is defined as hash' do
        let(:service_entrypoint) { '/bin/sh' }
        let(:service_alias) { 'db' }
        let(:service_command) { 'sleep 30' }
        let(:executor_opts) { { docker: { platform: 'amd64', user: 'dave' } } }
        let(:pull_policy) { %w[always if-not-present] }
        let(:job) do
          create(:ci_build, options: { services: [{ name: service_image_name, entrypoint: service_entrypoint,
                                                    alias: service_alias, command: service_command, ports: [80],
                                                    executor_opts: executor_opts, pull_policy: pull_policy }] })
        end

        it 'fabricates an non-empty array of objects' do
          is_expected.to be_kind_of(Array)
          is_expected.not_to be_empty
          expect(subject.first).to be_kind_of(described_class)
        end

        it 'populates fabricated objects with the proper attributes' do
          expect(subject.first.name).to eq(service_image_name)
          expect(subject.first.entrypoint).to eq(service_entrypoint)
          expect(subject.first.alias).to eq(service_alias)
          expect(subject.first.command).to eq(service_command)
          expect(subject.first.executor_opts).to eq(executor_opts)
          expect(subject.first.pull_policy).to eq(pull_policy)

          port = subject.first.ports.first
          expect(port.number).to eq 80
          expect(port.protocol).to eq 'http'
          expect(port.name).to eq 'default_port'
        end
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
