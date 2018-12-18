class GameInfo
  attr_reader :default_font
  attr_reader :screen_width
  attr_reader :screen_height
  attr_reader :debug_mode
  attr_reader :show_rotations
  attr_reader :enable_level_completion

  attr_accessor :state

  def initialize
    initialize_debug
  end

  def initialize_font(font)
    @default_font = font
  end

  def initialize_screen_size(width, height)
    @screen_width = width
    @screen_height = height
  end

  def initialize_debug
    @debug_mode = false
    @show_rotations = false
    @enable_level_completion = true
  end

  def initialize_state
    @state = :game
  end

  def toggle_level_completion
    @enable_level_completion = (not @enable_level_completion)
  end

  def toggle_debug_mode
    @debug_mode = (not @debug_mode)
  end

  def toggle_show_rotations
    @show_rotations = (not @show_rotations)
  end
end

class Vector2
  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  attr_accessor :x
  attr_accessor :y
end