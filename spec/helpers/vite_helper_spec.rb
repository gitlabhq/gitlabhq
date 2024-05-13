# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ViteHelper, feature_category: :tooling do
  describe '#vite_page_entrypoint_path' do
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
      end

      it { expect(helper.vite_page_entrypoint_paths).to eq(result) }
    end
  end

  describe '#universal_stylesheet_link_tag' do
    it do
      link_tag = Capybara.string(helper.universal_stylesheet_link_tag('application')).first('link', visible: :all)

      expect(link_tag[:rel]).to eq('stylesheet')
      expect(link_tag[:href]).to match_asset_path('application.css')
    end
  end

  describe '#universal_path_to_stylesheet' do
    it do
      expect(helper.universal_path_to_stylesheet('application')).to match_asset_path('application.css')
    end
  end
end
