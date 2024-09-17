# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::RandomDomain, feature_category: :pages do
  subject(:generator) do
    described_class.new(project_path: project_path)
  end

  RSpec.shared_examples 'random domain' do |domain|
    it do
      expect(SecureRandom)
        .to receive(:hex)
        .and_wrap_original do |_, size, _|
          ('h' * size * 2)
        end

      generated = generator.generate

      expect(generated).to eq(domain)
    end
  end

  context 'when project path is less than 48 chars' do
    let(:project_path) { 'p' }

    it_behaves_like 'random domain', 'p-hhhhhh'
  end

  context 'when project path is close to 48 chars' do
    let(:project_path) { 'p' * 56 }

    it_behaves_like 'random domain', 'pppppppppppppppppppppppppppppppppppppppppppppppppppppppp-hhhhhh'
  end

  context 'when project path is larger than 48 chars' do
    let(:project_path) { 'p' * 57 }

    it_behaves_like 'random domain', 'pppppppppppppppppppppppppppppppppppppppppppppppppppppppp-hhhhhh'
  end
end
