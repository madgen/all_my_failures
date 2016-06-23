# frozen_string_literal: true

module ColouredString
  refine String do
    def red
      "\e[31m#{self}\e[0m"
    end

    def light_blue
      "\e[36m#{self}\e[0m"
    end

    def green
      "\e[32m#{self}\e[0m"
    end
  end
end
