module Additionals
  module GlobalTestHelper
    def with_additionals_settings(settings, &_block)
      change_additionals_settings(settings)
      yield
    ensure
      restore_additionals_settings
    end

    def change_additionals_settings(settings)
      @saved_settings = Setting.plugin_additionals.dup
      new_settings = Setting.plugin_additionals.dup
      settings.each do |key, value|
        new_settings[key] = value
      end
      Setting.plugin_additionals = new_settings
    end

    def restore_additionals_settings
      if @saved_settings
        Setting.plugin_additionals = @saved_settings
      else
        Rails.logger.warn 'warning: restore_additionals_settings could not restore settings'
      end
    end

    def assert_query_sort_order(table_css, column, options = {})
      options[:action] = :index if options[:action].blank?
      column = column.to_s
      column_css = column.tr('_', '-')

      get options[:action],
          params: { sort: "#{column}:asc", c: [column] }

      assert_response :success
      assert_select "table.list.#{table_css}.sort-by-#{column_css}.sort-asc"

      get options[:action],
          params: { sort: "#{column}:desc", c: [column] }

      assert_response :success
      assert_select "table.list.#{table_css}.sort-by-#{column_css}.sort-desc"
    end

    def assert_dashboard_query_blocks(blocks = [])
      blocks.each do |block_def|
        block_def[:user_id]
        @request.session[:user_id] = block_def[:user_id].presence || 2
        get block_def[:action].presence || :show,
            params: { dashboard_id: block_def[:dashboard_id],
                      block: block_def[:block],
                      project_id: block_def[:project],
                      format: 'js' }

        assert_response :success, "assert_response for #{block_def[:block]}"
        assert_select "table.list.#{block_def[:entities_class]}"
      end
    end
  end
end
