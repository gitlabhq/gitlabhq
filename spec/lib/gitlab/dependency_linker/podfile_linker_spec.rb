# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::PodfileLinker do
  describe '.support?' do
    it 'supports Podfile' do
      expect(described_class.support?('Podfile')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('Podfile.lock')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Podfile" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        source 'https://github.com/artsy/Specs.git'
        source 'https://github.com/CocoaPods/Specs.git'

        platform :ios, '8.0'
        use_frameworks!
        inhibit_all_warnings!

        target 'Artsy' do
          pod 'AFNetworking', "~> 2.5"
          pod 'Interstellar/Core', git: 'https://github.com/ashfurrow/Interstellar.git', branch: 'observable-unsubscribe'
        end
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'links sources' do
      expect(subject).to include(link('https://github.com/artsy/Specs.git', 'https://github.com/artsy/Specs.git'))
      expect(subject).to include(link('https://github.com/CocoaPods/Specs.git', 'https://github.com/CocoaPods/Specs.git'))
    end

    it 'links packages' do
      expect(subject).to include(link('AFNetworking', 'https://cocoapods.org/pods/AFNetworking'))
    end

    it 'links external packages' do
      expect(subject).to include(link('Interstellar/Core', 'https://github.com/ashfurrow/Interstellar.git'))
    end

    it 'links Git repos' do
      expect(subject).to include(link('https://github.com/ashfurrow/Interstellar.git', 'https://github.com/ashfurrow/Interstellar.git'))
    end
  end
end
