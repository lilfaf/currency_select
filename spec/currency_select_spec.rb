require 'spec_helper'
require 'action_view'
require 'currency_select'
require 'money'

describe CurrencySelect do
  describe "currency_array" do
    context "currency_list is provided" do
      before :each do 
        CurrencySelect.currency_list = [["Foo", :bar]] 
      end

      it "should not hit require" do
        CurrencySelect.should_not_receive(:require)
        CurrencySelect.currencies_array
      end

      it "should render the currency_list" do
        CurrencySelect.currencies_array.should == [["Foo", :bar]]
      end
    end

    context "currency_list is not provided" do
      before :each do 
        CurrencySelect.currency_list = nil
      end
      
      it "should return the Money::Currency table" do
        CurrencySelect.currencies_array.count.should == Money::Currency.table.count
      end
    end
  end
end

module ActionView
  module Helpers
    describe CurrencySelect do
      before :each do 
        CurrencySelect.currency_list = nil
      end

      include TagHelper

      class User
        attr_accessor :currency_code
      end

      let(:user) { User.new }
      let(:template) { ActionView::Base.new }
      let(:select_tag) do
        "<select id=\"user_currency_code\" name=\"user[currency_code]\">"
      end

      let(:selected_eur_option) do
        if defined?(Tags::Base)
          content_tag(:option, 'Euro - EUR', selected: :selected, value: 'eur')
        else
          "<option value=\"eur\" selected=\"selected\">Euro - EUR</option>"
        end
      end

      let(:builder) do
        if defined?(Tags::Base)
          FormBuilder.new(:user, user, template, {})
        else
          FormBuilder.new(:user, user, template, {}, Proc.new { })
        end
      end

      describe "currency_select" do
        let(:tag) { builder.currency_select(:currency_code) }

        it "creates a select tag" do
          tag.should include(select_tag)
        end

        it "creates option tags for each currency" do
          ::CurrencySelect.currencies_array.each do |name, code|
            tag.should include(content_tag(:option, name, value: code))
          end
        end

        it "selects the value of currency_code" do
          user.currency_code = 'eur'
          t = builder.currency_select(:currency_code)
          t.should include(selected_eur_option)
        end

        it "does not mark two currencies as selected" do
          user.currency_code = "usd"
          str = "<option value=\"us\" selected=\"selected\">United States</option>".html_safe
          tag.should_not include(str)
        end

        describe "priority currencies" do
          let(:tag) { builder.currency_select(:currency_code, ['eur']) }

          it "inserts the priority currencies at the top" do
            tag.should include("#{select_tag}<option value=\"eur")
          end

          it "inserts a divider" do
            tag.should include("<option value=\"\" disabled=\"disabled\">-------------</option>")
          end
        end
      end
    end
  end
end
