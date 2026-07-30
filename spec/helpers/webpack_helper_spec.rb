# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebpackHelper, feature_category: :tooling do
  let(:source) { 'foo.js' }
  let(:asset_path) { "/assets/webpack/#{source}" }

  before do
    allow(helper).to receive(:vite_enabled?).and_return(false)
  end

  describe '#prefetch_link_tag' do
    it 'returns prefetch link tag' do
      expect(helper.prefetch_link_tag(source)).to eq("<link rel=\"prefetch\" href=\"/#{source}\">")
    end
  end

  describe '#webpack_preload_asset_tag' do
    before do
      allow(Gitlab::Webpack::Manifest).to receive(:asset_paths).and_return([asset_path])
      allow(helper).to receive(:content_security_policy_nonce).and_return('noncevalue')
    end

    it 'preloads the resource by default' do
      expect(helper).to receive(:preload_link_tag).with(asset_path, {}).and_call_original

      output = helper.webpack_preload_asset_tag(source)

      expect(output).to eq("<link rel=\"preload\" href=\"#{asset_path}\" as=\"script\" type=\"text/javascript\" nonce=\"noncevalue\">")
    end

    it 'prefetches the resource if explicitly asked' do
      expect(helper).to receive(:prefetch_link_tag).with(asset_path).and_call_original

      output = helper.webpack_preload_asset_tag(source, prefetch: true)

      expect(output).to eq("<link rel=\"prefetch\" href=\"#{asset_path}\">")
    end
  end

  context 'when vite enabled' do
    let(:bundle) { 'bundle.js' }

    before do
      stub_rails_env('development')

      allow(helper).to receive(:vite_javascript_tag).and_return('vite')
      allow(helper).to receive(:vite_enabled?).and_return(true)
    end

    describe '#webpack_bundle_tag' do
      it 'return vite javascript tag' do
        expect(helper.webpack_bundle_tag(bundle)).to eq('vite')
      end
    end
  end

  describe '#webpack_controller_bundle_tags with vue3 migration' do
    let(:user) { build_stubbed(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper.controller).to receive_messages(
        controller_path: 'projects/jobs',
        action_name: 'show'
      )
      allow(Gitlab::Webpack::Manifest).to receive(:entrypoint_paths) do |entry|
        raise Gitlab::Webpack::Manifest::AssetMissingError unless served_entries.include?(entry)

        ["/assets/webpack/#{entry}.js"]
      end
    end

    context 'when the page is committed to Vue 3' do
      let(:served_entries) { ['pages.projects.jobs.show.vue3'] }

      before do
        # Default to the real implementation, then override only the specific
        # entry name we care about. The broader stub must be declared first;
        # otherwise the narrower stub would be overwritten by it.
        allow(Gitlab::Vue3Migration).to receive(:entrypoint_for).and_call_original
        allow(Gitlab::Vue3Migration).to receive(:entrypoint_for)
          .with('pages.projects.jobs.show', current_user: user)
          .and_return('pages.projects.jobs.show.vue3')
      end

      it 'renders the .vue3 entry' do
        expect(helper.webpack_controller_bundle_tags).to include('pages.projects.jobs.show.vue3.js')
      end
    end

    context 'when the .vue3 entry is missing from the manifest' do
      let(:served_entries) { ['pages.projects.jobs.show'] }

      before do
        allow(Gitlab::Vue3Migration).to receive(:entrypoint_for).and_call_original
        allow(Gitlab::Vue3Migration).to receive(:entrypoint_for)
          .with('pages.projects.jobs.show', current_user: user)
          .and_return('pages.projects.jobs.show.vue3')
      end

      it 'falls back to the original entry' do
        output = helper.webpack_controller_bundle_tags

        expect(output).to include('pages.projects.jobs.show.js')
        expect(output).not_to include('.vue3.js')
      end
    end
  end
end
