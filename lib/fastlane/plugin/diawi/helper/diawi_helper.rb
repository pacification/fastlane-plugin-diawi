module Fastlane
  module Helper
    class DiawiHelper
      # class methods that you define here become available in your action
      # as `Helper::DiawiHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the diawi plugin helper!")
      end
    end
  end
end
