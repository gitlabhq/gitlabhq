require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/redirect_with_status'

describe RuboCop::Cop::RedirectWithStatus do
  include CopHelper

  subject(:cop) { described_class.new }
  let(:controller_fixture_without_status) do
    %q(
      class UserController < ApplicationController
        def show
          user = User.find(params[:id])
          redirect_to user_path if user.name == 'John Wick'
        end

        def destroy
          user = User.find(params[:id])

          if user.destroy
            redirect_to root_path
          else
            render :show
          end
        end
      end
    )
  end

  let(:controller_fixture_with_status) do
    %q(
      class UserController < ApplicationController
        def show
          user = User.find(params[:id])
          redirect_to user_path if user.name == 'John Wick'
        end

        def destroy
          user = User.find(params[:id])

          if user.destroy
            redirect_to root_path, status: 302
          else
            render :show
          end
        end
      end
    )
  end

  context 'in controller' do
    before do
      allow(cop).to receive(:in_controller?).and_return(true)
    end

    it 'registers an offense when a "destroy" action uses "redirect_to" without "status"' do
      inspect_source(cop, controller_fixture_without_status)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([12]) # 'redirect_to' is located on 12th line in controller_fixture.
        expect(cop.highlights).to eq(['redirect_to'])
      end
    end

    it 'does not register an offense when a "destroy" action uses "redirect_to" with "status"' do
      inspect_source(cop, controller_fixture_with_status)

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context 'outside of controller' do
    it 'registers no offense' do
      inspect_source(cop, controller_fixture_without_status)
      inspect_source(cop, controller_fixture_with_status)

      expect(cop.offenses.size).to eq(0)
    end
  end
end
