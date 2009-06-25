module ActiveRecord
  module AttributeSearchable
  
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Make an ActiveRecord model searchable by its attributes. Adds a +search+ method which enhances the
      # functionality of +find+. 
      # 
      # When declaring a model as attribute_searchable, you may also optionally specify which attributes are 
      # searched when using the +:terms+ filter. See example below.
      #
      # ==== Example
      # To search a Product's name, description or tags attributes when filtering +:terms+:
      #   class Product < ActiveRecord::Base
      #     attribute_searchable :terms_attributes => [:name, :description, :tags]
      #     ...
      #   end
      #
      #   # To filter products by the terms 'blue' and 'large', the following statement will generate the SQL conditions:
      #   # ...WHERE (product.name ILIKE '%blue%' OR
      #   #           product.description ILIKE '%blue%' OR
      #   #           product.tags ILIKE '%blue%')
      #   #
      #   #      AND (product.name ILIKE '%large%' OR
      #   #           product.description ILIKE '%large%' OR
      #   #           product.tags ILIKE '%large%')
      #   product_instance.search(:all, :terms => %w{blue large})
      def attribute_searchable(options = {})
        extend ActiveRecord::AttributeSearchable::SingletonMethods
        include ActiveRecord::AttributeSearchable::InstanceMethods

        unless options[:terms_attributes].nil?
          self.terms_attributes = [*options[:terms_attributes]] 
        end
      end
    end

    module SingletonMethods
      # Search the current model's attributes for the given +:filters+ option. All parameters
      # and options other than +:filters+ and +:conditions+ are passed on to the +ActiveRecordd:Based.find+
      # method. +:conditions+ are built from the +:filters+ option, and passed on.
      #
      # === Filtering by Terms
      # +terms+ allow a model's string attributes to be quickly searched using an SQL (I)LIKE clause.
      # To specify which attributes are searched when filtering terms, set the +:terms_attributes+ option
      # when making a model +attribute_searchable+ (See above). For example, to specify a User's first_name,
      # last_name and email_address attributes are searched when filtering by +:terms+:
      #
      #   class User < ActiveRecord::Base
      #     attribute_searchable :terms_attributes => [:first_name, :last_name, :email_address]
      #     ...
      #   end
      #
      # In the example model, above, any :terms filters will now be converted into the following conditions:
      #
      #   WHERE first_name ILIKE %term% OR
      #         last_name ILIKE %term% OR
      #         email_address ILIKE %term%
      #         ...
      #
      # When multiple terms are specified, each term will be joined by a SQL AND clause, for example:
      #
      #   WHERE (first_name ILIKE %term_1% OR
      #         last_name ILIKE %term_1% OR
      #         email_address ILIKE %term_1%)
      #         AND
      #         (first_name ILIKE %term_2% OR
      #         last_name ILIKE %term_2% OR
      #         email_address ILIKE %term_2%)
      #         ...
      #
      #
      # ==== Options
      # +:filters+ A hash of filters (see below) that will be applied to the finder results.
      # 
      # ==== Filters
      # +:terms+ An array of word terms that will be used to filter the record. The join between terms is AND. See +attribute_searchable+ for determining which attributes are searched using +:terms+.
      #
      # ==== Examples
      # To find a user record by the terms "mary" AND "jones"
      #   User.search :all, :filters => {:terms %w{mary jones}}
      #
      # To find all users whose admin status is true:
      #   User.search :all, :filters => {:admin => true}
      #
      # To find the first user whose first_name is "John" and is unverified
      #  User.search :first, :filters => {:first_name => "John", :verified_at => nil}
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

    protected
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
