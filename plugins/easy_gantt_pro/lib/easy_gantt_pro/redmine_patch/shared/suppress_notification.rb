module EasyGanttPro
  module SuppressNotification

    def self.included(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods

      def notify?
        if RequestStore.store[:easy_gantt_suppress_notification] == true
          false
        else
          super
        end
      end

    end

  end
end

RedmineExtensions::PatchManager.register_model_patch ['Issue', 'Journal'], 'EasyGanttPro::SuppressNotification'
