class EmptyController < ApplicationController
  def index
    render :text => "Trying to reload... (maybe it triggers, maybe it does not)"
  end
end
