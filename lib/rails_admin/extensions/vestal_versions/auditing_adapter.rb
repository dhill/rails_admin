module RailsAdmin
  module Extensions
    module VestalVersions

      class VersionProxy

        def initialize(version, user_class = User)
          @version = version
          @user_class = user_class
        end

        #-------------------------------------------------------------------------------

        def message
          "#{event} #{@version.versioned_type} id #{@version.versioned_id}"
        end

        #-------------------------------------------------------------------------------

        def created_at
          @version.created_at
        end

        #-------------------------------------------------------------------------------

        def table
          @version.versioned_type
        end

        #-------------------------------------------------------------------------------

        def username
          @user_class.find_by_id(@version.user_name).try(:email) || @version.user_name
        end

        #-------------------------------------------------------------------------------

        def item
          @version.versioned_id
        end

        #-------------------------------------------------------------------------------
        private
        #-------------------------------------------------------------------------------

        def event
          if @version.number == 1
            event = "created"
          elsif @version.tag == "deleted"
            event = @version.tag
          else
            event = "updated"
          end
        end

      end

      #-------------------------------------------------------------------------------

      class AuditingAdapter

        COLUMN_MAPPING = {
          :item         => :versioned_id,
          :table        => :versioned_type,
          :username     => :user_name,
          :created_at   => :created_at,
          :message      => :modifications
        }

        #-------------------------------------------------------------------------------

        def initialize(controller, user_class = User)
          raise "VestalVersions not found" unless defined?(VestalVersions)

          @controller = controller
          @user_class = user_class.to_s.constantize
        end

        #-------------------------------------------------------------------------------

        def latest
          ::Version.limit(100).map { |version| VersionProxy.new(version, @user_class) }
        end

        #-------------------------------------------------------------------------------

        def delete_object(message, object, model, user)
          # do nothing
        end

        #-------------------------------------------------------------------------------

        def update_object(model, object, associations_before, associations_after, modified_associations, old_object, user)
          # do nothing
        end

        #-------------------------------------------------------------------------------

        def create_object(message, object, abstract_model, user)
          # do nothing
        end

        #-------------------------------------------------------------------------------

        def listing_for_model(model, query, sort, sort_reverse, all, page, 
                                per_page = (RailsAdmin::Config.default_items_per_page || 20))
          version_listing(model, nil, query, sort, sort_reverse, all, page, per_page)
        end

        #-------------------------------------------------------------------------------

        def listing_for_object(model, object, query, sort, sort_reverse, all, page, 
                                  per_page = (RailsAdmin::Config.default_items_per_page || 20))
          version_listing(model, object, query, sort, sort_reverse, all, page, per_page)
        end

        #-------------------------------------------------------------------------------
        private
        #-------------------------------------------------------------------------------

        def version_listing(model, object, query, sort, sort_reverse, all, page, per_page)
          if sort.present?
            sort = COLUMN_MAPPING[sort.to_sym]
          else
            sort = :created_at
            sort_reverse = "true"
          end

          conditions = { :versioned_type => model.model.name }
          conditions.merge(:versioned_id => object.id) if object.present?

          versions = ::Version.where(conditions)
          versions = versions.where("number LIKE ?", "%#{query}%") if query.present?
          versions = versions.order(sort_reverse == "true" ? "#{sort} DESC" : sort)

          unless all
            versions = versions.send(Kaminari.config.page_method_name, page.presence || "1").per(per_page)
          end

          versions.map { |version| VersionProxy.new(version, @user_class) }
        end

      end
    end
  end
end

class Version < ActiveRecord::Base
end

