# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Interpolator, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }

  let(:ctx) { instance_double(Gitlab::Ci::Config::External::Context, project: project, user: build(:user, id: 1234)) }
  let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(config: [header, content]) }

  subject { described_class.new(result, arguments, ctx) }

  context 'when input data is valid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'correctly interpolates the config' do
      subject.interpolate!

      expect(subject).to be_valid
      expect(subject.to_hash).to eq({ test: 'deploy gitlab.com' })
    end

    it 'tracks the event' do
      expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
        .with('ci_interpolation_users', { values: 1234 })

      subject.interpolate!
    end
  end

  context 'when config has a syntax error' do
    let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(error: ArgumentError.new) }

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid config' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include 'content does not have a valid YAML syntax'
    end
  end

  context 'when spec header is invalid' do
    let(:header) do
      { spec: { arguments: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid header' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include('header:spec config contains unknown keys: arguments')
    end
  end

  context 'when interpolation block is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.abc ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'correctly interpolates the config' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.errors).to include 'unknown interpolation key: `abc`'
      expect(subject.error_message).to eq 'interpolation interrupted by errors, unknown interpolation key: `abc`'
    end
  end

  context 'when provided interpolation argument is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: ['gitlab.com'] }
    end

    it 'correctly interpolates the config' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include 'unsupported value in input argument `website`'
    end
  end

  context 'when multiple interpolation blocks are invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'correctly interpolates the config' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq 'interpolation interrupted by errors, unknown interpolation key: `something`'
    end
  end

  describe '#to_hash' do
    context 'when interpolation is disabled' do
      before do
        stub_feature_flags(ci_includable_files_interpolation: false)
      end

      let(:header) do
        { spec: { inputs: { website: nil } } }
      end

      let(:content) do
        { test: 'deploy $[[ inputs.website ]]' }
      end

      let(:arguments) { {} }

      it 'returns an empty hash' do
        subject.interpolate!

        expect(subject.to_hash).to be_empty
      end
    end

    context 'when interpolation is not used' do
      let(:result) do
        ::Gitlab::Ci::Config::Yaml::Result.new(config: content)
      end

      let(:content) do
        { test: 'deploy production' }
      end

      let(:arguments) { nil }

      it 'returns original content' do
        subject.interpolate!

        expect(subject.to_hash).to eq(content)
      end
    end

    context 'when interpolation is available' do
      let(:header) do
        { spec: { inputs: { website: nil } } }
      end

      let(:content) do
        { test: 'deploy $[[ inputs.website ]]' }
      end

      let(:arguments) do
        { website: 'gitlab.com' }
      end

      it 'correctly interpolates content' do
        subject.interpolate!

        expect(subject.to_hash).to eq({ test: 'deploy gitlab.com' })
      end
    end
  end

  describe '#ready?' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'returns false if interpolation has not been done yet' do
      expect(subject).not_to be_ready
    end

    it 'returns true if interpolation has been performed' do
      subject.interpolate!

      expect(subject).to be_ready
    end

    context 'when interpolation can not be performed' do
      let(:result) do
        ::Gitlab::Ci::Config::Yaml::Result.new(error: ArgumentError.new)
      end

      it 'returns true if interpolator has preliminary errors' do
        expect(subject).to be_ready
      end

      it 'returns true if interpolation has been attempted' do
        subject.interpolate!

        expect(subject).to be_ready
      end
    end
  end

  describe '#interpolate?' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    context 'when interpolation can be performed' do
      it 'will perform interpolation' do
        expect(subject.interpolate?).to eq true
      end
    end

    context 'when interpolation is disabled' do
      before do
        stub_feature_flags(ci_includable_files_interpolation: false)
      end

      it 'will not perform interpolation' do
        expect(subject.interpolate?).to eq false
      end
    end

    context 'when an interpolation header is missing' do
      let(:header) { nil }

      it 'will not perform interpolation' do
        expect(subject.interpolate?).to eq false
      end
    end

    context 'when interpolator has preliminary errors' do
      let(:result) do
        ::Gitlab::Ci::Config::Yaml::Result.new(error: ArgumentError.new)
      end

      it 'will not perform interpolation' do
        expect(subject.interpolate?).to eq false
      end
    end
  end

  describe '#has_header?' do
    let(:content) do
      { test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    context 'when header is an empty hash' do
      let(:header) { {} }

      it 'does not have a header available' do
        expect(subject).not_to have_header
      end
    end

    context 'when header is not specified' do
      let(:header) { nil }

      it 'does not have a header available' do
        expect(subject).not_to have_header
      end
    end
  end
end
