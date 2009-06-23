module ActiveRecord
  module AttributeSearchable
  
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def attribute_searchable(options = {})
        extend ActiveRecord::AttributeSearchable::SingletonMethods
        include ActiveRecord::AttributeSearchable::InstanceMethods

        unless options[:terms_attributes].nil?
          self.terms_attributes = [*options[:terms_attributes]] 
        end
      end
    end

    module SingletonMethods
      # Search the current model's attributes for the given +filters+ option. All options
      # other than +:conditions+ are passed on to the +find+ method.
      #
      # For more information, see the +terms+ option in +attribute_searchable+ above.
      #
      # ==== Examples
      # To find a user record by terms:
      #   User.search(:all, :filters
      def search(*args)
        options = args.extract_options!
        filters = options.delete(:filters) || {}

        combined_conditions = Caboose::EZ::Condition.new

        unless filters[:terms].nil? or self.terms_attributes.nil?
          filters[:terms].each do |term|
            term = ['%', term, '%'].join

            condition = Caboose::EZ::Condition.new
            self.terms_attributes.each do |column|
              condition.append ["#{column.to_s} LIKE ?", term], :or
            end

            combined_conditions << condition
          end
        end

        options[:conditions] = combined_conditions.to_sql

        self.find(args.first, options)
      end


      def terms_attributes
        @terms_attributes
      end

      def terms_attributes=(value)
        @terms_attributes = value
      end

    end

    module InstanceMethods
    end
  
  end
end
