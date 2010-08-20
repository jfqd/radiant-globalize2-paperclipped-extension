class Globalize2PaperclippedExtension < Radiant::Extension
  version "0.1"
  description "Translate Paperclipped Assets using Radiant Globalize2 Extension."
  url "http://blog.aissac.ro/radiant/globalize2-paperclipped-extension/"
  
  def activate
    throw "Globalize2 Extension must be loaded before Globalize2Paperclipped" unless defined?(Globalize2Extension)
    throw "Paperclipped Extension must be loaded before Globalize2Paperclipped" unless defined?(PaperclippedExtension)
    
    PaperclippedExtension.admin.asset.index.add :top, 'admin/shared/change_locale_admin'
    PaperclippedExtension.admin.asset.edit.add :main, 'admin/shared/change_asset_locale', :before => 'edit_form'  
    
    PaperclippedExtension.admin.asset.index.add :thead, 'admin/shared/globalize_th'
    PaperclippedExtension.admin.asset.index.add :tbody, 'admin/shared/globalize_asset_td'
    
    Asset.send(:translates, *[:title, :caption])
    
    # Asset.send(:include, Globalize2Paperclipped::AssetExtensions)
    Page.send(:include, Globalize2Paperclipped::Globalize2PaperclippedTags)
    Page.send(:include, Globalize2Paperclipped::PageExtensions)
    
    #compatibility
    Asset.send(:include, Globalize2Paperclipped::Compatibility::TinyPaper::AssetExtensions) if defined?(TinyPaperExtension)
  
    # not nice to include it right in this class, but working ;-)
    Asset.class_eval {
      def self.search(search, filter, page)
        unless search.blank?
      
          search_cond_sql = []
          search_cond_sql << 'LOWER(assets.asset_file_name) LIKE (:term)'
          search_cond_sql << 'LOWER(asset_translations.title) LIKE (:term)'
          search_cond_sql << 'LOWER(asset_translations.caption) LIKE (:term)'
          
          cond_sql = "(#{ search_cond_sql.join(" or ") }) AND asset_translations.locale = (:locale)"
      
          @conditions = [cond_sql, {:term => "%#{search.downcase}%", :locale => I18n.locale.to_s}]
        else
          @conditions = ['asset_translations.locale = ?', I18n.locale.to_s]
        end
      
        options = { :conditions => @conditions,
                    :joins => "INNER JOIN asset_translations ON asset_translations.asset_id = assets.id",
                    :order => 'created_at DESC',
                    :page => page,
                    :per_page => 10 }
      
        @file_types = filter.blank? ? [] : filter.keys
        if not @file_types.empty?
          options[:total_entries] = count_by_conditions
          Asset.paginate_by_content_types(@file_types, :all, options )
        else
          Asset.paginate(:all, options)
        end
      end

      def self.count_by_conditions
        join = "INNER JOIN asset_translations ON asset_translations.asset_id = assets.id"
        type_conditions = @file_types.blank? ? nil : Asset.types_to_conditions(@file_types.dup).join(" OR ")
        @count_by_conditions ||= @conditions.empty? ? Asset.count(:all, :conditions => type_conditions, :joins => join) : Asset.count(:all, :conditions => @conditions, :joins => join)
      end
    }
  
  end
  
  def deactivate
  end
  
end
