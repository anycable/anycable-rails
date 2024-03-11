# frozen_string_literal: true

module AnyCable
  module Rails
    module ObjectSerializer
      module_function

      # Serialize via GlobalID if available
      def serialize(obj)
        obj.try(:to_gid_param)
      end

      # Deserialize from GlobalID
      def deserialize(str)
        GlobalID::Locator.locate(str)
      end
    end
  end
end
