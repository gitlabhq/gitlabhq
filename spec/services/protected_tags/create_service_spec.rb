# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTags::CreateService do
  let(:project) { create(:project) }
  let(:user) { project.first_owner }
  let(:params) do
    {
      name: name,
      create_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  describe '#execute' do
    let(:name) { 'tag' }

    subject(:service) { described_class.new(project, user, params) }

    it 'creates a new protected tag' do
      expect { service.execute }.to change(ProtectedTag, :count).by(1)
      expect(project.protected_tags.last.create_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
    end

    context 'when name has escaped HTML' do
      let(:name) { 'tag-&gt;test' }

      it 'creates the new protected tag matching the unescaped version' do
        expect { service.execute }.to change(ProtectedTag, :count).by(1)
        expect(project.protected_tags.last.name).to eq('tag->test')
      end

      context 'and name contains HTML tags' do
        let(:name) { '&lt;b&gt;tag&lt;/b&gt;' }

        it 'creates the new protected tag with sanitized name' do
          expect { service.execute }.to change(ProtectedTag, :count).by(1)
          expect(project.protected_tags.last.name).to eq('tag')
        end

        context 'and contains unsafe HTML' do
          let(:name) { '&lt;script&gt;alert(&#39;foo&#39;);&lt;/script&gt;' }

          it 'does not create the new protected tag' do
            expect { service.execute }.not_to change(ProtectedTag, :count)
          end
        end
      end

      context 'when name contains unescaped HTML tags' do
        let(:name) { '<b>tag</b>' }

        it 'creates the new protected tag with sanitized name' do
          expect { service.execute }.to change(ProtectedTag, :count).by(1)
          expect(project.protected_tags.last.name).to eq('tag')
        end
      end
    end
  end
end
