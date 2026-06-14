# frozen_string_literal: true

module Rpg
  module Shop
    class ShowView < Charming::View
      def render
        column(heading, gold_line, stock_list, messages, hint, gap: 1)
      end

      private

      def heading
        text "Merchant", style: theme.title
      end

      def gold_line
        text "Souls: #{world.player.souls}", style: theme.hud
      end

      def stock_list
        return text "The merchant has nothing to sell.", style: theme.muted if world.shop_stock.empty?

        rows = world.shop_stock.each_with_index.map do |item, index|
          price_tag = "#{item.value}g"
          stat = Equipment.stat_line(item.stats.symbolize_keys)
          text "#{index + 1}. #{item.name} — #{price_tag}  #{stat}", style: theme.text
        end
        column(*rows)
      end

      def messages
        recent = world.messages.last(2)
        return column if recent.empty?

        rows = recent.map { |m| text m, style: theme.log }
        column(*rows)
      end

      def hint
        text "Press 1/2/3 to buy, esc or $ to return.", style: theme.muted
      end
    end
  end
end
