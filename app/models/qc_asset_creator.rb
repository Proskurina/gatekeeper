##
# Our plate creators work on behalf of the controllers
# They ensure we can composite the relevant behaviour based
# on the asset, without cluttering up the controller.
class QcAssetCreator

  class QcAssetException < StandardError; end

  attr_reader :api, :purpose, :sibling, :sibling2, :tag2_tubes
  ##
  # Receives the parent asset, and composites itself
  def initialize(api:,asset:,user:,purpose:,sibling: nil,template: nil, tag2_tubes:nil, sibling2: nil)
    @api,@asset,@user,@purpose,@sibling,@template,@tag2_tubes = api,asset,user,purpose,sibling,template,tag2_tubes
    @sibling2 = sibling2
    self.extend behaviour_module
  end

  def tag2_locations_for_barcode(barcode)
    tube = @tag2_tubes.select{|pos, t| t[:barcode]== barcode}
    info = tube.values[0]
    info[:target_well_locations]
  end

  def tag2_tubes_barcodes
    return nil if @tag2_tubes.nil?
    Hash[@tag2_tubes.map{|pos, tube| [pos, tube[:barcode]] }]
  end

  ##
  # Calls the appropriate api calls and returns the newly created asset
  def create!
    validate!
    asset_update_state
    asset_create.tap do |child|
      asset_transfer(child)
    end
  end

  def asset_update_state
    api.state_change.create!(
      :user => @user.uuid,
      :target => @asset.uuid,
      :target_state => 'passed'
    )
  end

  def asset_create
    raise StandardError, 'Create not yet implemented for this asset!'
  end

  def asset_transfer
    raise StandardError, 'Transfer not yet implemented for this asset!'
  end

  private

  ##
  # Determines which module to extend with
  def behaviour_module
    behaviour_module_name= 'plate_creation'
    if Settings.purposes.has_key?(@asset.purpose.uuid)
      behaviour_module_name = Settings.purposes[@asset.purpose.uuid].with || behaviour_module_name
    else
      unless Settings.default_purpose.nil? || Settings.default_purpose.with.nil?
        behaviour_module_name = Settings.default_purpose.with
      end
    end
    return "QcAssetCreator::#{behaviour_module_name.classify}".constantize
  end


  ##
  # Determines which transfer template to use
  def transfer_template
    api.transfer_template.find(@template||default_template)
  end

  def default_template
    Settings.transfer_templates['Transfer columns 1-12']
  end

end
