require 'uri'

module KubernetesCookbook
  module PathNameHelper
    module_function

    def kubernetes_file(uri) 
      File.basename(URI.parse(uri).path)
    end
  end
end

