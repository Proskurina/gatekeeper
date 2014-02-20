##
# Designed to present information about lots
# Takes an api object and wraps the methods neatly
class Presenter::Lot

  class ConfigurationError < StandardError; end

  attr_reader :lot

  def initialize(lot)
    @lot = lot
  end

  def lot_type
    @lot.lot_type_name
  end

  delegate :lot_number, :to=> :lot

  def received_at
    @lot.received_at.to_date.strftime('%d/%m/%Y')
  end

  def template
    @lot.template_name
  end

  def total_plates
    @total||= @lot.qcables.count
  end

  ##
  # Returns each state, excluding any passed in as arguments
  # Aliased as each_state for readability where all states are needed
  def each_state_except(reject=[])
    state_counts.reject{|k,_| reject.include?(k) }.each do |state,count|
      yield(state,count,count*100.0/total_plates)
    end
  end
  alias_method :each_state, :each_state_except

  ##
  # Yields for each state, and provides an array of Qcable presenters
  def each_state_and_plates(reject=[])
    sorted_qcables.each do |state,qcables|
      yield state, Presenter::Qcable.new_from_batch(qcables)
    end
  end

  ##
  # Keeps track of the active tab. It will return true the first time it is called,
  # and subsequently is called with the same state again.
  def active?(state)
    (@active||=state) == state ? 'active' : ''
  end

  private

  def state_index(state)
    [
      'created',
      'qc_in_progress',
      'failed',
      'destroyed',
      'passed',
      'exhausted',
      'pending',
      'available'
     ].index(state)
  end

  def sorted_qcables
    @sorted ||= @lot.qcables.group_by {|qcable| qcable.state }.sort {|a,b| state_index(a.first)<=>state_index(b.first)}
  end

  def state_counts
    @counts ||= sorted_qcables.map {|state,qcables| [state,qcables.count]}
  end

end