module ActiveRecord
  module AttributeSearchable
  
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def attribute_searchable
        extend ActiveRecord::AttributeSearchable::SingletonMethods
        include ActiveRecord::AttributeSearchable::InstanceMethods
      end
    end

    module SingletonMethods
      def search(*args)
        options = args.extract_options!

        self.find(args.first, options)
      end
    end

    module InstanceMethods
    end
  
  end
end
