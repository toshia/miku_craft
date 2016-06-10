# -*- coding: utf-8 -*-

require_relative '../../test_config.rb'
require File.join(MikuCraftRoot, 'plugin', 'campaign', 'mc_json')

describe 'Minecraft JSON' do
  # before do
  #   load File.join(MikuCraftRoot, 'plugin', 'campaign.rb')
  # end

  describe 'Numeric' do
    it '整数' do
      assert_equal '1', 1.to_mcjson(binding)
      assert_equal '10', 10.to_mcjson(binding)
      assert_equal '123456789', 123456789.to_mcjson(binding)
    end

    it 'ゼロ' do
      assert_equal '0', 0.to_mcjson(binding)
    end

    it '負の数' do
      assert_equal '-1', -1.to_mcjson(binding)
      assert_equal '-10', -10.to_mcjson(binding)
      assert_equal '-123456789', -123456789.to_mcjson(binding)
    end

    it '少数' do
      assert_equal '1.0', 1.0.to_mcjson(binding)
      assert_equal '-1.25', -1.25.to_mcjson(binding)
      assert_equal '12345.6789', 12345.6789.to_mcjson(binding)
    end
  end

  describe '文字列' do
    it '空文字' do
      assert_equal '""', ''.to_mcjson(binding)
    end

    it '日本語' do
      assert_equal '"ゲバ棒"', 'ゲバ棒'.to_mcjson(binding)
    end

    it 'ERBによる文字列差し込み' do
      user_name = Matsuya.order
      args = Struct.new(:user_name, :login_count).new(user_name, 0)
      assert_equal "\"#{user_name}記念！\"", '<%= user_name %>記念！'.to_mcjson(args.__send__(:binding))
    end
  end
end
