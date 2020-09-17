module EasyGanttPro
  module IssuesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_action :easy_gantt_suppress_notification
      end
    end

    module InstanceMethods

      private

        def easy_gantt_suppress_notification
          RequestStore.store[:easy_gantt_suppress_notification] = (params[:issue] && params[:issue][:easy_gantt_suppress_notification] == 'true')
        end

    end
  end
end
RedmineExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyGanttPro::IssuesControllerPatch'
