class ExamplesController < ApplicationController


  def show
    @h1_text = 'John Dugan'
    byebug
    respond_to do |format|
      format.docx { headers["Content-Disposition"] = "attachment; filename=\"caracal.docx\"" }
    end
  end
end
