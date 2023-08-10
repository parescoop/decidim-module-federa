

# Aggiunti instance method al model workflow
module Decidim
  module Verifications
    class WorkflowManifest

      def system_name
        fullname.concat(name.match(/_identity/) ? " (tenant: #{name.gsub("_identity", "")})" : '')
      end

    end
  end
end