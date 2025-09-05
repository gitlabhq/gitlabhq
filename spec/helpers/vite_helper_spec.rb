# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ViteHelper, feature_category: :tooling do
  describe '#vite_page_entrypoint_paths' do
    using RSpec::Parameterized::TableSyntax

    where(:path, :action, :result) do
      'some_path' | 'create' | %w[pages.some_path.js pages.some_path.new.js]
      'some_path' | 'new'    | %w[pages.some_path.js pages.some_path.new.js]
      'some_path' | 'update' | %w[pages.some_path.js pages.some_path.edit.js]
      'some_path' | 'show'   | %w[pages.some_path.js pages.some_path.show.js]
      'some/long' | 'path'   | %w[pages.some.js pages.some.long.js pages.some.long.path.js]
    end

    with_them do
      before do
        allow(helper.controller).to receive(:controller_path).and_return(path)
        allow(helper.controller).to receive(:action_name).and_return(action)
        allow(ViteRuby.instance.manifest).to receive(:path_for).and_return("/some/path")
      end

      it { expect(helper.vite_page_entrypoint_paths).to eq(result) }
    end

    context 'with js_action_name instance variable set' do
      before do
        allow(helper.controller).to receive(:controller_path).and_return('some_path')
        allow(helper.controller).to receive(:action_name).and_return('new')
        allow(ViteRuby.instance.manifest).to receive(:path_for).and_return("/some/path")
      end

      it 'accepts custom action name' do
        expect(helper.vite_page_entrypoint_paths('new_2')).to eq(%w[pages.some_path.js pages.some_path.new_2.js])
      end
    end

    context 'with missing entrypoint' do
      before do
        allow(helper.controller).to receive(:controller_path).and_return('some_path')
        allow(helper.controller).to receive(:action_name).and_return('new')
        allow(ViteRuby.instance.manifest).to receive(:path_for).and_raise(
          ViteRuby::MissingEntrypointError.new(
            file_name: 'some/path.js',
            last_build: ViteRuby::Build.new,
            manifest: ViteRuby.instance.manifest,
            config: ViteRuby.instance.config
          )
        )
      end

      it 'returns empty assets' do
        expect(helper.vite_page_entrypoint_paths).to eq([])
      end
    end
  end

  describe '#universal_stylesheet_link_tag' do
    let_it_be(:path) { 'application' }

    subject(:link_tag) { Capybara.string(helper.universal_stylesheet_link_tag(path)).first('link', visible: :all) }

    context 'when Vite is disabled' do
      before do
        allow(helper).to receive(:vite_enabled?).and_return(false)
      end

      it 'uses stylesheet_link_tag' do
        expect(helper).to receive(:stylesheet_link_tag).with(path).and_call_original

        expect(link_tag[:rel]).to eq('stylesheet')
        expect(link_tag[:href]).to match_asset_path("#{path}.css")
      end
    end

    context 'when Vite is enabled' do
      before do
        allow(helper).to receive(:vite_enabled?).and_return(true)

        allow(ViteRuby.instance.manifest).to receive(:path_for)
                                               .with("styles/#{path}.css", type: :stylesheet)
                                               .and_return("/assets/vite/styles/#{path}.css")
      end

      it 'uses vite_stylesheet_tag' do
        expect(link_tag[:rel]).to eq('stylesheet')
        expect(link_tag[:href]).to eq('/assets/vite/styles/application.css')
      end
    end
  end

  describe '#universal_path_to_stylesheet' do
    let_it_be(:path) { 'application' }
    let_it_be(:out_path) { 'out/application' }

    context 'when Vite is disabled' do
      before do
        allow(helper).to receive(:vite_enabled?).and_return(false)
      end

      it 'uses path_to_stylesheet' do
        expect(helper.universal_path_to_stylesheet(path)).to match_asset_path("#{path}.css")
      end
    end

    context 'when Vite is enabled' do
      before do
        allow(helper).to receive(:vite_enabled?).and_return(true)
        allow(ViteRuby.instance.manifest).to receive(:path_for)
                                               .with("styles/#{path}.css")
                                               .and_return(out_path)
      end

      it 'uses vite_asset_path' do
        expect(helper.universal_path_to_stylesheet(path)).to be(out_path)
      end
    end
  end
end
