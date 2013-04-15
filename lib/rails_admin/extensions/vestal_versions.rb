require 'rails_admin/extensions/vestal_versions/auditing_adapter'

RailsAdmin.add_extension(:vestal_versions, RailsAdmin::Extensions::VestalVersions, {
  :auditing => true
})
