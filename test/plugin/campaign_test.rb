# -*- coding: utf-8 -*-

require_relative '../test_config.rb'
require 'yaml'

describe 'Campaign Plugin' do
  before do
    pluggaloid_clear
    load File.join(MikuCraftRoot, 'plugin', 'campaign.rb')
  end

  it 'プラグインをロードできる' do
    Plugin.instance_exist? :campaign
  end

  describe 'キャンペーンがない時' do
    before do
      Plugin.call(:give_continuous_login_bonus, 'toshi_a', 1)
    end

    it 'giftbox_keepイベントは発生しない' do
      refute_event :giftbox_keep, 'キャンペーン無いのになんか渡されたぞ'
    end
  end

  describe '年次キャンペーンの境界チェック' do
    before do
      plugin do
        filter_campaign_table do |x|
          [YAML.safe_load(<<YML)] end end end
---
- name: "キャンペーンA"
  start: [1, 2]
  end:   [1, 5]
  type: item_random
  table:
    - id: 'minecraft:diamond_hoe'
- name: "キャンペーンB"
  start: [1, 7]
  end:   [1, 10]
  type: item_random
  table:
    - id: 'minecraft:iron_hoe'
- name: "重複キャンペーン"
  start: [1, 9]
  end:   [1, 11]
  type: item_random
  table:
    - id: 'minecraft:gold_hoe'
YML
    describe 'テーブル上の全てのイベントの前' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 1)] end end end

      it 'アクティブなイベントは存在しない' do
        assert_empty Plugin::Campaign::Campaign.active_campaigns end end

    describe 'イベント開始日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 2)] end end end

      it '1つのキャンペーンがアクティブ' do
        assert_equal 1, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンAがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンA'} end end

    describe 'イベント中日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 3)] end end end

      it '1つのキャンペーンがアクティブ' do
        assert_equal 1, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンAがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンA'} end end

    describe 'イベント最終日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 5)] end end end

      it '1つのキャンペーンがアクティブ' do
        assert_equal 1, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンAがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンA'} end end

    describe 'イベント翌日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 6)] end end end

      it 'アクティブなイベントは存在しない' do
        assert_empty Plugin::Campaign::Campaign.active_campaigns end end

    describe '重複キャンペーン(先)開始日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 7)] end end end

      it '1つのキャンペーンがアクティブ' do
        assert_equal 1, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンBがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンB'} end end

    describe '重複キャンペーン(後)開始日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 9)] end end end

      it '2つのキャンペーンがアクティブ' do
        assert_equal 2, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンBがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンB'} end

      it '重複キャンペーンがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == '重複キャンペーン'} end end

    describe '重複キャンペーン(先)終了日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 10)] end end end

      it '2つのキャンペーンがアクティブ' do
        assert_equal 2, Plugin::Campaign::Campaign.active_campaigns.size end

      it 'キャンペーンBがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == 'キャンペーンB'} end

      it '重複キャンペーンがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == '重複キャンペーン'} end end

    describe '重複キャンペーン(後)終了日' do
      before do
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 1, 11)] end end end

      it '1つのキャンペーンがアクティブ' do
        assert_equal 1, Plugin::Campaign::Campaign.active_campaigns.size end

      it '重複キャンペーンがアクティブ' do
        assert Plugin::Campaign::Campaign.active_campaigns.any?{|x|x.name == '重複キャンペーン'} end end

  end

  describe 'item_randomキャンペーン' do
    describe '一種類だけ' do
      before do
        @dummy_campaign_name = Matsuya.order
        @table = [{ name: @dummy_campaign_name,
                    type: 'item_random',
                    start: [1,1],
                    end: [1,1],
                    table: [{id: 'minecraft:rabbit_stew'}]}]
      end

      describe 'NBTタグなし' do
        before do
          table = @table
          plugin do
            filter_today_date do |x|
              [Date.new(2000, 1, 1)]
            end
            filter_campaign_table do |x|
              [table]
            end
          end
          Plugin.call(:give_continuous_login_bonus, 'toshi_a', 1)
        end

        it 'アイテムを獲得する' do
          assert_events(
            giftbox_keep: [
              'toshi_a',
              ->x{ x.include?(@dummy_campaign_name) && x.include?('minecraft:rabbit_stew') },
              'minecraft:rabbit_stew',
              ->x{true},
              ->x{true},
              '{}' ])
        end
      end

      describe 'NBTタグあり' do
        before do
          @dummy_item_name = Matsuya.order
          table = @table
          table[0][:table][0][:NBT] = {display: {Name: @dummy_item_name}}
          plugin do
            filter_today_date do |x|
              [Date.new(2000, 1, 1)]
            end
            filter_campaign_table do |x|
              [table]
            end
          end
          Plugin.call(:give_continuous_login_bonus, 'toshi_a', 1)
        end

        it 'アイテムを獲得する' do
          assert_events(
            giftbox_keep: [
              'toshi_a',
              ->x{ x.include?(@dummy_campaign_name) && x.include?(@dummy_item_name) && !x.include?('minecraft:rabbit_stew') },
              'minecraft:rabbit_stew',
              ->x{true},
              ->x{true},
              @table[0][:table][0][:NBT].to_mcjson(binding) ])
        end
      end
    end

    describe 'ERBで内容をカスタマイズ' do
      before do
        @teokure = 10
        @dummy_campaign_name = "<%= user_name %>お誕生日イベント"
        @dummy_name = Matsuya.order
        @user_name = 'shijin_cmpb'
        @age = 114514
        @table = [{ name: @dummy_campaign_name,
                    type: 'item_random',
                    start: [12,20],
                    end: [12,25],
                    table: [{id: 'minecraft:cake',
                             NBT: {display: {Name: @dummy_name, Lole: '<%= user_name %>くん<%= login_count %>歳おめでとう'}}}]}]
        table = @table
        plugin do
          filter_today_date do |x|
            [Date.new(2000, 12, 23)]
          end
          filter_campaign_table do |x|
            [table]
          end
        end
        Plugin.call(:give_continuous_login_bonus, @user_name, @age)
      end

      it 'ERBコードが適切に実行されている' do
        user_name, login_count = @user_name, @age
        dummy_campaign_name = ERB.new(@dummy_campaign_name).result(binding)
        assert_events(
          giftbox_keep: [
            @user_name,
            ->x{ x.include?(dummy_campaign_name) },
            'minecraft:cake',
            ->x{true},
            ->x{true},
            @table[0][:table][0][:NBT].to_mcjson(binding) ])
      end

    end
  end
end

