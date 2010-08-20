module Globalize2Paperclipped
  module AssetExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def scope_locale(locale, &block)
        with_scope(:find => { :joins => "INNER JOIN asset_translations atrls ON atrls.asset_id = assets.id", :conditions => ['atrls.locale = ?', locale] }) do
          yield
        end
      end      
    end 
  end
end