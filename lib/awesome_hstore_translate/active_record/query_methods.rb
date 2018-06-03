module AwesomeHstoreTranslate
  module ActiveRecord
    module QueryMethods
      def where(opts = :chain, *rest)
        if opts.is_a?(Hash)
          query = spawn
          translated_attrs = translated_attributes(opts)
          untranslated_attrs = untranslated_attributes(opts)

          unless untranslated_attrs.empty?
            query.where!(untranslated_attrs, *rest)
          end

          translated_attrs.each do |key, value|
            if value.is_a?(String)
              query.where!(":value = any(avals(#{get_column_name(key)}))", value: value)
            else
              super
            end
          end

          query
        else
          super
        end
      end

      def order(*args)
        if args.is_a?(Array)
          check_if_method_has_arguments!(:order, args)
          query = spawn
          attrs = args

          # TODO Remove this ugly hack
          if args[0].is_a?(Hash)
            attrs = args[0]
          elsif args[0].is_a?(Symbol)
            attrs = Hash[args.map {|attr| [attr, :asc]}]
          end

          translated_attrs = translated_attributes(attrs)
          untranslated_attrs = untranslated_attributes(attrs)

          unless untranslated_attrs.empty?
            query.order!(untranslated_attrs)
          end

          translated_attrs.each do |key, value|
            query.order!("#{get_column_name(key)} -> '#{I18n.locale.to_s}' #{value}")
          end

          query
        else
          super
        end
      end

      private

      def get_column_name(attr)
        column_name = attr.to_s
        # detect column from original hstore_translate
        old_column_name = "#{column_name}_translations"

        return old_column_name if !has_attribute?(column_name) && has_attribute?(old_column_name)

        column_name
      end

      def translated_attributes(opts)
        opts.select{ |key, _| self.translated_attribute_names.include?(key.to_sym) }
      end

      def untranslated_attributes(opts)
        opts.reject{ |key, _| self.translated_attribute_names.include?(key.to_sym) }
      end
    end
  end
end